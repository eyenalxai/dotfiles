#!/usr/bin/env bash
# Update every git repo under a directory, several at a time, with live progress.
#
# Normal mode just pulls. --trim additionally makes each repo:
#   * shallow, keeping only commits from the last N months
#   * single-branch, keeping only the remote's default branch
#   * free of old tags and unreachable objects
#
# Usage:
#   ./update-repos.sh                     # pull all repos under this script's folder
#   ./update-repos.sh -r ~/Projects/other # search a different folder
#   ./update-repos.sh -j 16               # update 16 repos at once (default 8)
#   ./update-repos.sh -m next             # only repos whose path contains "next"
#   ./update-repos.sh -l                  # list repos, don't pull
#   ./update-repos.sh -t 300              # per-repo timeout (default 180s)
#   ./update-repos.sh --trim              # pull + keep only last 3 months, one branch
#   ./update-repos.sh --trim --months 6   # same, with a 6-month window
#
# Exit codes: 0 = everything fine, 1 = at least one repo failed or stalled.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT="$SCRIPT_DIR"
TIMEOUT=180
MONTHS=3
MATCH=""
LIST_ONLY=0
TRIM=0
JOBS=8

usage() {
  cat <<'EOF'
Update every git repo under a directory, several at a time, with live progress.

Usage: update-repos.sh [options]

  -r, --root DIR      Folder to search (default: folder containing this script)
  -t, --timeout SECS  Kill a pull that runs longer than this (default: 180)
  -j, --jobs N        Update N repos at once (default: 8)
  -m, --match TEXT    Only pull repos whose path contains TEXT
  -l, --list          List matching repos and exit
      --trim          Keep at most the last N months of commits and only the
                      remote's default branch (destructive to other branches,
                      tags, and unpushed work)
      --months N      History window for --trim (default: 3; implies --trim)
  -h, --help          Show this help

Normal output per repo: a live block with one spinner per running repo (name,
elapsed time, last git progress line), then a result line as each one finishes.

--trim detects the default branch from refs/remotes/origin/HEAD (falling
back to git ls-remote). It then fetches only that branch, drops other
branches and old tags, and runs gc. The history window is a maximum:
clones that are already shallower (e.g. depth 1) are never deepened.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -r|--root)    ROOT="${2:?--root needs a value}"; shift 2 ;;
    -t|--timeout) TIMEOUT="${2:?--timeout needs a value}"; shift 2 ;;
    -j|--jobs)    JOBS="${2:?--jobs needs a value}"; shift 2 ;;
    -m|--match)   MATCH="${2:?--match needs a value}"; shift 2 ;;
    -l|--list)    LIST_ONLY=1; shift ;;
    --trim)       TRIM=1; shift ;;
    --months)     MONTHS="${2:?--months needs a value}"; TRIM=1; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "${0##*/}: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$TIMEOUT" in
  ''|*[!0-9]*) echo "${0##*/}: --timeout must be a number of seconds" >&2; exit 2 ;;
esac
case "$JOBS" in
  ''|*[!0-9]*) echo "${0##*/}: --jobs must be a number" >&2; exit 2 ;;
esac
[ "$JOBS" -gt 0 ] || { echo "${0##*/}: --jobs must be greater than zero" >&2; exit 2; }
case "$MONTHS" in
  ''|*[!0-9]*) echo "${0##*/}: --months must be a number" >&2; exit 2 ;;
esac
[ "$MONTHS" -gt 0 ] || { echo "${0##*/}: --months must be greater than zero" >&2; exit 2; }

[ -d "$ROOT" ] || { echo "${0##*/}: not a directory: $ROOT" >&2; exit 2; }
ROOT="$(cd -- "$ROOT" && pwd)"
CUTOFF="${MONTHS} months ago"
CUTOFF_TS=$(LC_ALL=C date -d "$CUTOFF" +%s 2>/dev/null) || CUTOFF_TS=0
case "$CUTOFF_TS" in ''|*[!0-9]*) CUTOFF_TS=0 ;; esac
GC_TIMEOUT=$((TIMEOUT * 5))
(( GC_TIMEOUT < 600 )) && GC_TIMEOUT=600

export LC_ALL=C
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/bin/true
export GIT_EDITOR=true
export GIT_MERGE_AUTOEDIT=no
export GIT_PAGER=cat
export GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=15'

IS_TTY=0
if [ -t 1 ]; then
  IS_TTY=1
  B=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GRN=$'\e[32m'; YEL=$'\e[33m'; CYN=$'\e[36m'; RST=$'\e[0m'
else
  B=; DIM=; RED=; GRN=; YEL=; CYN=; RST=
fi

# ---------- find repos ----------
REPOS=()
while IFS= read -r -d '' gitdir; do
  repo="${gitdir%/.git}"
  [ -n "$MATCH" ] && [[ "$repo" != *"$MATCH"* ]] && continue
  REPOS+=("$repo")
done < <(find "$ROOT" -maxdepth 4 -type d -name .git -prune -print0 2>/dev/null | sort -z)

TOTAL=${#REPOS[@]}
if [ "$TOTAL" -eq 0 ]; then
  if [ -n "$MATCH" ]; then
    echo "No git repos matching \"$MATCH\" under $ROOT"
  else
    echo "No git repos found under $ROOT"
  fi
  exit 0
fi
(( JOBS > TOTAL )) && JOBS=$TOTAL

if [ "$TOTAL" -eq 1 ]; then REPO_NOUN="repo"; else REPO_NOUN="repos"; fi
if [ "$MONTHS" -eq 1 ]; then MONTH_NOUN="month"; else MONTH_NOUN="months"; fi

if [ "$LIST_ONLY" -eq 1 ]; then
  for repo in "${REPOS[@]}"; do
    printf '%s\n' "${repo#"$ROOT"/}"
  done
  printf '%d %s\n' "$TOTAL" "$REPO_NOUN"
  exit 0
fi

# ---------- helpers ----------
shorten() {
  local s="$1" max="$2"
  if (( ${#s} > max )); then
    printf '%s…' "${s:0:max-1}"
  else
    printf '%s' "$s"
  fi
}

last_log_line() {
  tail -c 4000 "$1" 2>/dev/null | tr '\r' '\n' | awk 'NF { line=$0 } END { print line }'
}

plural() {
  if [ "$1" -eq 1 ]; then printf '%s' "$2"; else printf '%s' "$3"; fi
}

human_kb() {
  awk -v k="$1" 'BEGIN {
    split("KB MB GB TB", u, " "); i = 1;
    while (k >= 1024 && i < 4) { k /= 1024; i++ }
    if (i == 1) printf "%d%s", k, u[i]; else printf "%.1f%s", k, u[i]
  }'
}

default_branch() {
  local repo="$1" ref=""
  ref=$(git -C "$repo" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null) || ref=""
  ref=${ref#origin/}
  [ "$ref" = "HEAD" ] && ref=""
  if [ -z "$ref" ]; then
    ref=$(timeout 15 git -C "$repo" ls-remote --symref origin HEAD 2>/dev/null |
      awk '/^ref:/ { sub("refs/heads/", "", $2); print $2; exit }')
  fi
  printf '%s' "$ref"
}

# newest commit timestamp among the shallow boundary commits (0 if unknown)
shallow_boundary_ts() {
  local repo="$1" gitdir="$2" sha ts newest=0
  [ -f "$gitdir/shallow" ] || { printf '0'; return; }
  while IFS= read -r sha; do
    [ -z "$sha" ] && continue
    ts=$(git -C "$repo" show -s --format=%ct "$sha" 2>/dev/null) || ts=0
    (( ts > newest )) && newest=$ts
  done <"$gitdir/shallow"
  printf '%s' "$newest"
}

# ---------- per-job workspace and cleanup ----------
WORK=$(mktemp -d "${TMPDIR:-/tmp}/update-repos.XXXXXX") || { echo "cannot create temp dir" >&2; exit 1; }
PIDS=()

cleanup_children() {
  local p
  for p in "${PIDS[@]}"; do kill "$p" 2>/dev/null; done
  rm -rf "$WORK"
}
trap 'cleanup_children; exit 130' INT TERM
trap cleanup_children EXIT

NEXT=1
RUNNING_COUNT=0
OK=0; UPDATED=0; TRIMMED=0; FAILED=0; STALLED=0; SKIPPED=0
TOTAL_SAVED_KB=0
RUN_START=$SECONDS
declare -a PID=() RUNNING=() STATUS=() DETAIL=()
declare -a STARTED=() LAST_SIZE=() LAST_CHANGE=() LABELS=()
LIVE=0
TICK=0

# run a command, capturing its output in the given log; sets JOB_CHILD while it runs
run_logged() {
  local log="$1"; shift
  local rc
  "$@" >"$log" 2>&1 &
  JOB_CHILD=$!
  wait "$JOB_CHILD"; rc=$?
  JOB_CHILD=""
  return "$rc"
}

# record a finished job: status, seconds, detail, saved KB
job_done() {
  local status="$1" dur="$2" detail="${3//$'\n'/ }" saved="${4:-0}"
  printf '%s\037%s\037%s\037%s\n' "$status" "$dur" "$saved" "$detail" >"$JOB_RES.tmp" &&
    mv -f "$JOB_RES.tmp" "$JOB_RES"
}

# ---------- job runners (each runs inside its own worker subshell) ----------
pull_one() {
  local repo="$1" idx="$2"
  local name="${repo#"$ROOT"/}"
  local start dur rc before after status detail="" col="" label=""

  if [ "$IS_TTY" -eq 1 ]; then
    label="[$idx/$TOTAL] $name "
  else
    printf '[%d/%d] %s ... ' "$idx" "$TOTAL" "$name"
  fi

  # bare repo: nothing to pull
  if [ "$(git -C "$repo" rev-parse --is-bare-repository 2>/dev/null)" = "true" ]; then
    printf '%s–%s %s%sskipped (bare repo)%s\n' "$DIM" "$RST" "$label" "$DIM" "$RST"
    job_done "skipped" 0 "bare repository"
    return
  fi

  start=$SECONDS
  before=$(git -C "$repo" rev-parse --verify HEAD 2>/dev/null || true)

  run_logged "$JOB_LOG" timeout -k 5 "$TIMEOUT" git -C "$repo" pull --progress
  rc=$?
  dur=$((SECONDS-start))
  after=$(git -C "$repo" rev-parse --verify HEAD 2>/dev/null || true)

  if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    status="stalled"; col=$YEL
    detail="killed after ${TIMEOUT}s"
    local stuck
    stuck=$(last_log_line "$JOB_LOG")
    printf '%s⏱%s %s%sstalled%s — no result after %ss\n' "$col" "$RST" "$label" "$col" "$RST" "$TIMEOUT"
    [ -n "$stuck" ] && printf '    %slast output: %s%s\n' "$DIM" "$(shorten "$stuck" 120)" "$RST"
    printf '    %shint: network/DNS/credentials may be stuck; try that repo by hand%s\n' "$DIM" "$RST"
  elif [ "$rc" -ne 0 ]; then
    status="failed"; col=$RED
    local err
    err=$(tr '\r' '\n' <"$JOB_LOG" | awk '/^(fatal|error):/ { print; exit }')
    if [ -z "$err" ]; then
      err=$(tr '\r' '\n' <"$JOB_LOG" | awk 'NF && $0 !~ /^(warning|hint):/ { print; exit }')
    fi
    [ -z "$err" ] && err="git pull exited with status $rc"
    detail=$(shorten "$err" 200)
    printf '%s✗%s %s%sfailed%s · %ss\n' "$col" "$RST" "$label" "$col" "$RST" "$dur"
    tr '\r' '\n' <"$JOB_LOG" | awk 'NF' | tail -n 12 | sed 's/^/    /'
  elif [ "$before" = "$after" ]; then
    status="up to date"; col=$DIM
    detail=""
    printf '%s✓%s %s%sup to date · %ss%s\n' "$GRN" "$RST" "$label" "$DIM" "$dur" "$RST"
  else
    status="updated"; col=$GRN
    local n=""
    if [ -n "$before" ] && [ -n "$after" ]; then
      n=$(git -C "$repo" rev-list --count "$before..$after" 2>/dev/null || true)
    fi
    if [ -n "$n" ]; then detail="$n new commit(s)"; else detail="new commits"; fi
    printf '%s↑%s %s%supdated%s · %s · %ss\n' "$col" "$RST" "$label" "$GRN" "$RST" "$detail" "$dur"
  fi

  job_done "$status" "$dur" "$detail"
}

trim_one() {
  local repo="$1" idx="$2"
  local name="${repo#"$ROOT"/}"
  local start dur rc branch gitdir before_kb after_kb saved
  local tags_before tags_after branches_removed=0 ahead=0
  local was_detached=0 detached_at="" label=""
  local fetch_shallow=1 boundary_ts=0 shallow_note="" cerr="" chk_rc=0
  local -a fetch_args

  if [ "$IS_TTY" -eq 1 ]; then
    label="[$idx/$TOTAL] $name "
  else
    printf '[%d/%d] %s ... ' "$idx" "$TOTAL" "$name"
  fi

  if [ -n "$(git -C "$repo" status --porcelain -uno 2>/dev/null)" ]; then
    printf '%s–%s %s%sskipped (uncommitted changes)%s\n' "$DIM" "$RST" "$label" "$DIM" "$RST"
    job_done "skipped" 0 "uncommitted changes"
    return
  fi
  if [ -n "$(git -C "$repo" stash list 2>/dev/null)" ]; then
    printf '%s–%s %s%sskipped (stash present)%s\n' "$DIM" "$RST" "$label" "$DIM" "$RST"
    job_done "skipped" 0 "stash present"
    return
  fi

  branch=$(default_branch "$repo")
  if [ -z "$branch" ]; then
    printf '%s✗%s %s%sfailed%s · could not detect default branch\n' "$RED" "$RST" "$label" "$RED" "$RST"
    job_done "failed" 0 "could not detect default branch"
    return
  fi

  gitdir=$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null) || gitdir=""
  if [ -z "$gitdir" ]; then
    printf '%s✗%s %s%sfailed%s · cannot resolve .git directory\n' "$RED" "$RST" "$label" "$RED" "$RST"
    job_done "failed" 0 "cannot resolve .git directory"
    return
  fi

  # Never deepen an existing shallow clone: if its boundary is already newer
  # than the cutoff it has less than the maximum window, so fetch as-is.
  if [ "$(git -C "$repo" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
    boundary_ts=$(shallow_boundary_ts "$repo" "$gitdir")
    if [ "$CUTOFF_TS" -eq 0 ] || [ "$boundary_ts" -eq 0 ] || [ "$boundary_ts" -gt "$CUTOFF_TS" ]; then
      fetch_shallow=0
      shallow_note="kept existing shallower history (not deepened)"
    fi
  fi

  start=$SECONDS
  before_kb=$(du -sk "$gitdir" 2>/dev/null | cut -f1) || before_kb=0

  if ! git -C "$repo" symbolic-ref -q HEAD >/dev/null 2>&1; then
    was_detached=1
    detached_at=$(git -C "$repo" describe --tags --always 2>/dev/null || true)
  fi
  tags_before=$(git -C "$repo" tag 2>/dev/null | wc -l)

  # future fetches only follow the default branch
  if ! git -C "$repo" remote set-branches origin "$branch" 2>/dev/null; then
    printf '%s✗%s %s%sfailed%s · cannot narrow origin refspec\n' "$RED" "$RST" "$label" "$RED" "$RST"
    job_done "failed" 0 "cannot narrow origin refspec"
    return
  fi

  fetch_args=(fetch --prune --progress)
  if [ "$fetch_shallow" -eq 1 ]; then
    fetch_args+=(--shallow-since="$CUTOFF")
  fi
  run_logged "$JOB_LOG" timeout -k 5 "$TIMEOUT" \
    git -C "$repo" "${fetch_args[@]}" origin
  rc=$?

  # A repo whose newest commit is already older than the window cannot satisfy
  # --shallow-since. Keep just the tip (depth 1); that is still <= the window.
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 124 ] && [ "$rc" -ne 137 ] &&
    grep -q 'no commits selected for shallow' "$JOB_LOG"; then
    printf '    %sno commits within the window; keeping tip only (depth 1)%s\n' "$DIM" "$RST"
    run_logged "$JOB_LOG" timeout -k 5 "$TIMEOUT" \
      git -C "$repo" fetch --prune --progress --depth 1 origin
    rc=$?
  fi
  if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    printf '%s⏱%s %s%sstalled%s — fetch killed after %ss\n' "$YEL" "$RST" "$label" "$YEL" "$RST" "$TIMEOUT"
    job_done "stalled" 0 "fetch killed after ${TIMEOUT}s"
    return
  elif [ "$rc" -ne 0 ]; then
    local err
    err=$(tr '\r' '\n' <"$JOB_LOG" | awk '/^(fatal|error):/ { print; exit }')
    [ -z "$err" ] && err=$(last_log_line "$JOB_LOG")
    [ -z "$err" ] && err="git fetch exited with status $rc"
    printf '%s✗%s %s%sfailed%s · %ss\n' "$RED" "$RST" "$label" "$RED" "$RST" "$(shorten "$err" 160)"
    tr '\r' '\n' <"$JOB_LOG" | awk 'NF' | tail -n 8 | sed 's/^/    /'
    job_done "failed" 0 "$(shorten "$err" 200)"
    return
  fi

  # now that origin/<default> is current, see what local work would be dropped
  if (( was_detached == 0 )); then
    ahead=$(git -C "$repo" rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo 0)
  fi

  # put the working tree on the default branch at origin's tip
  timeout 60 git -C "$repo" checkout -q -B "$branch" "origin/$branch" >"$JOB_LOG" 2>&1
  chk_rc=$?
  if [ "$chk_rc" -ne 0 ]; then
    cerr=$(tr '\r' '\n' <"$JOB_LOG" | awk 'NF { print; exit }')
    [ -z "$cerr" ] && cerr="git checkout exited with status $chk_rc"
    printf '%s✗%s %s%sfailed%s · checkout: %s\n' "$RED" "$RST" "$label" "$RED" "$RST" "$(shorten "$cerr" 140)"
    tr '\r' '\n' <"$JOB_LOG" | awk 'NF' | tail -n 8 | sed 's/^/    /'
    job_done "failed" 0 "checkout: $(shorten "$cerr" 180)"
    return
  fi
  git -C "$repo" branch --set-upstream-to="origin/$branch" "$branch" >/dev/null 2>&1 || true
  git -C "$repo" symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$branch" >/dev/null 2>&1 || true

  # drop every local branch except the default one
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    [ "$b" = "$branch" ] && continue
    if git -C "$repo" branch -D "$b" >/dev/null 2>&1; then
      branches_removed=$((branches_removed+1))
    fi
  done < <(git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads/)

  # drop remote-tracking refs except origin/<default>
  while IFS= read -r ref; do
    case "$ref" in
      "refs/remotes/origin/$branch"|refs/remotes/origin/HEAD) continue ;;
    esac
    git -C "$repo" update-ref -d "$ref" 2>/dev/null || true
  done < <(git -C "$repo" for-each-ref --format='%(refname)' refs/remotes/)

  # keep only tags reachable from the kept branch
  git -C "$repo" tag >"$JOB_LOG" 2>/dev/null || true
  git -C "$repo" tag --merged HEAD >"$JOB_LOG.keep" 2>/dev/null || true
  LC_ALL=C sort -o "$JOB_LOG" "$JOB_LOG"
  LC_ALL=C sort -o "$JOB_LOG.keep" "$JOB_LOG.keep"
  comm -23 "$JOB_LOG" "$JOB_LOG.keep" >"$JOB_LOG.del" 2>/dev/null || true
  if [ -s "$JOB_LOG.del" ]; then
    xargs -r -d '\n' -n 200 git -C "$repo" tag -d <"$JOB_LOG.del" >/dev/null 2>&1 || true
  fi
  tags_after=$(git -C "$repo" tag 2>/dev/null | wc -l)

  # drop reflogs so old objects become unreachable, then delete them
  git -C "$repo" reflog expire --expire=now --all >/dev/null 2>&1 || true
  run_logged "$JOB_LOG" timeout -k 10 "$GC_TIMEOUT" \
    git -C "$repo" gc --prune=now --quiet
  rc=$?
  rm -f "$JOB_LOG.keep" "$JOB_LOG.del"
  if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    printf '%s⏱%s %s%sfailed%s · gc killed after %ss (refs were already pruned)\n' \
      "$YEL" "$RST" "$label" "$YEL" "$RST" "$GC_TIMEOUT"
    job_done "stalled" 0 "gc killed after ${GC_TIMEOUT}s"
    return
  elif [ "$rc" -ne 0 ]; then
    printf '%s✗%s %s%sfailed%s · gc exited with status %s (refs were already pruned)\n' \
      "$RED" "$RST" "$label" "$RED" "$RST" "$rc"
    job_done "failed" 0 "gc exited with status $rc"
    return
  fi

  dur=$((SECONDS-start))
  after_kb=$(du -sk "$gitdir" 2>/dev/null | cut -f1) || after_kb=0
  saved=$((before_kb-after_kb))
  (( saved < 0 )) && saved=0
  local commits detail commit_noun
  commits=$(git -C "$repo" rev-list --count HEAD 2>/dev/null) || commits=0
  commit_noun=$(plural "$commits" commit commits)

  detail="$branch, $commits $commit_noun"
  printf '%s✓%s %s%strimmed%s · %s · %s %s · %s → %s · %ss\n' \
    "$GRN" "$RST" "$label" "$GRN" "$RST" "$branch" "$commits" "$commit_noun" \
    "$(human_kb "$before_kb")" "$(human_kb "$after_kb")" "$dur"
  if (( branches_removed > 0 )); then
    printf '    %sdropped %s other local %s%s\n' "$DIM" "$branches_removed" \
      "$(plural "$branches_removed" branch branches)" "$RST"
  fi
  if (( tags_after < tags_before )); then
    printf '    %sdropped %s old %s, kept %s reachable %s%s\n' "$DIM" "$((tags_before-tags_after))" \
      "$(plural "$((tags_before-tags_after))" tag tags)" "$tags_after" \
      "$(plural "$tags_after" tag tags)" "$RST"
  fi
  if (( was_detached == 1 )); then
    printf '    %swas detached at %s; now on %s%s\n' "$DIM" "${detached_at:-unknown}" "$branch" "$RST"
  fi
  if (( ahead > 0 )); then
    printf '    %sdiscarded %s local %s on %s%s\n' "$YEL" "$ahead" \
      "$(plural "$ahead" commit commits)" "$name" "$RST"
  fi
  if (( saved > 0 )); then
    printf '    %sreclaimed %s%s\n' "$DIM" "$(human_kb "$saved")" "$RST"
  fi
  if [ -n "$shallow_note" ]; then
    printf '    %s%s%s\n' "$DIM" "$shallow_note" "$RST"
  fi

  job_done "trimmed" "$dur" "$detail" "$saved"
}

worker() {
  local repo="$1" idx="$2"
  JOB_LOG="$WORK/$idx.log"
  JOB_RES="$WORK/$idx.res"
  JOB_CHILD=""
  trap 'if [ -n "$JOB_CHILD" ]; then kill "$JOB_CHILD" 2>/dev/null; fi; exit 130' INT TERM
  if [ "$TRIM" -eq 1 ]; then trim_one "$repo" "$idx"; else pull_one "$repo" "$idx"; fi
}

# ---------- live dashboard ----------
live_erase() {
  (( IS_TTY == 1 && LIVE > 0 )) || { LIVE=0; return 0; }
  local i
  printf '\r\e[%dA' "$LIVE"
  for ((i=0; i<LIVE; i++)); do printf '\e[K\n'; done
  LIVE=0
}

live_draw() {
  (( IS_TTY == 1 )) || return 0
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i el quiet size maxw line elcol q n=0
  local fr="${frames[TICK % ${#frames[@]}]}"
  maxw=$(( ${COLUMNS:-80} - 46 ))
  (( maxw < 20 )) && maxw=20
  (( LIVE > 0 )) && printf '\r\e[%dA' "$LIVE"
  for ((i=1; i<=TOTAL; i++)); do
    (( ${RUNNING[i]:-0} == 1 )) || continue
    el=$((SECONDS - ${STARTED[i]:-$SECONDS}))
    size=0
    [ -f "$WORK/$i.log" ] && size=$(wc -c <"$WORK/$i.log" 2>/dev/null)
    if [ "$size" != "${LAST_SIZE[i]:-0}" ]; then
      LAST_SIZE[i]=$size
      LAST_CHANGE[i]=$SECONDS
    fi
    quiet=$((SECONDS - ${LAST_CHANGE[i]:-$SECONDS}))
    line=$(shorten "$(last_log_line "$WORK/$i.log")" "$maxw")
    elcol=$CYN
    (( el * 2 > TIMEOUT )) && elcol=$YEL
    (( el * 10 > TIMEOUT * 8 )) && elcol=$RED
    q=""
    (( quiet >= 10 )) && q="  silent ${quiet}s"
    printf '\e[K%s%s%s %s%s%s %s%3ds%s%s %s%s%s\n' \
      "$CYN" "$fr" "$RST" "$B" "${LABELS[i]}" "$RST" \
      "$elcol" "$el" "$RST" "$q" "$DIM" "$line" "$RST"
    n=$((n+1))
  done
  LIVE=$n
}

start_job() {
  local idx="$1" repo="$2"
  LABELS[idx]="[$idx/$TOTAL] ${repo#"$ROOT"/} "
  ( worker "$repo" "$idx" ) >"$WORK/$idx.out" 2>&1 &
  PID[idx]=$!
  PIDS+=("$!")
  RUNNING[idx]=1
  STARTED[idx]=$SECONDS
  LAST_CHANGE[idx]=$SECONDS
  LAST_SIZE[idx]=0
  RUNNING_COUNT=$((RUNNING_COUNT+1))
}

complete_job() {
  local idx="$1" rc=0
  local status dur saved detail name
  local res="$WORK/$idx.res"
  name="${REPOS[$((idx-1))]#"$ROOT"/}"

  wait "${PID[idx]}" 2>/dev/null; rc=$?
  if [ -f "$res" ]; then
    IFS=$'\037' read -r status dur saved detail <"$res"
  else
    status="failed"; dur=$((SECONDS - ${STARTED[idx]:-$SECONDS})); saved=0
    detail="worker exited unexpectedly (status $rc)"
  fi

  live_erase
  [ -s "$WORK/$idx.out" ] && cat "$WORK/$idx.out"
  if [ ! -f "$res" ]; then
    printf '%s✗%s %s%sfailed%s · %s\n' "$RED" "$RST" "$B" "$name" "$RST" "$detail"
  fi

  STATUS[idx]="$status"
  DETAIL[idx]="$detail"
  RUNNING[idx]=0
  RUNNING_COUNT=$((RUNNING_COUNT-1))

  case "$status" in
    "up to date") OK=$((OK+1)) ;;
    updated) UPDATED=$((UPDATED+1)) ;;
    trimmed) TRIMMED=$((TRIMMED+1)); TOTAL_SAVED_KB=$((TOTAL_SAVED_KB+saved)) ;;
    failed) FAILED=$((FAILED+1)) ;;
    stalled) STALLED=$((STALLED+1)) ;;
    skipped) SKIPPED=$((SKIPPED+1)) ;;
  esac
}

# ---------- main ----------
if [ "$TRIM" -eq 1 ]; then
  echo "${B}Trimming $TOTAL $REPO_NOUN under $ROOT${RST} to the last ${MONTHS} ${MONTH_NOUN}, default branch only"
else
  echo "${B}Updating $TOTAL $REPO_NOUN under $ROOT${RST} (timeout ${TIMEOUT}s each)"
fi
if (( JOBS > 1 )); then
  echo "${DIM}$JOBS at a time${RST}"
fi
echo

while (( NEXT <= TOTAL || RUNNING_COUNT > 0 )); do
  while (( RUNNING_COUNT < JOBS && NEXT <= TOTAL )); do
    start_job "$NEXT" "${REPOS[$((NEXT-1))]}"
    NEXT=$((NEXT+1))
  done

  for ((i=1; i<=TOTAL; i++)); do
    (( ${RUNNING[i]:-0} == 1 )) || continue
    if [ -f "$WORK/$i.res" ] || ! kill -0 "${PID[i]}" 2>/dev/null; then
      complete_job "$i"
    fi
  done

  if (( RUNNING_COUNT > 0 )); then
    TICK=$((TICK+1))
    live_draw
    sleep 0.15
  fi
done
live_erase

# ---------- summary ----------
elapsed=$((SECONDS-RUN_START))
mins=$((elapsed/60)); secs=$((elapsed%60))
[ "$mins" -gt 0 ] && dur_txt="${mins}m ${secs}s" || dur_txt="${secs}s"

echo
printf '%s────────────────────────────────────────%s\n' "$DIM" "$RST"
if [ "$TRIM" -eq 1 ]; then
  printf '%s%d %s in %s:%s %d trimmed, %d failed, %d stalled, %d skipped\n' \
    "$B" "$TOTAL" "$REPO_NOUN" "$dur_txt" "$RST" "$TRIMMED" "$FAILED" "$STALLED" "$SKIPPED"
  if (( TOTAL_SAVED_KB > 0 )); then
    printf '%sreclaimed %s%s\n' "$DIM" "$(human_kb "$TOTAL_SAVED_KB")" "$RST"
  fi
else
  printf '%s%d %s in %s:%s %d up to date, %d updated, %d failed, %d stalled, %d skipped\n' \
    "$B" "$TOTAL" "$REPO_NOUN" "$dur_txt" "$RST" "$OK" "$UPDATED" "$FAILED" "$STALLED" "$SKIPPED"
fi

if (( FAILED + STALLED > 0 )); then
  echo
  echo "${B}Needs attention:${RST}"
  for ((i=1; i<=TOTAL; i++)); do
    case "${STATUS[i]:-}" in
      failed)  printf '  %s✗ %s%s — %s\n' "$RED" "${REPOS[$((i-1))]#"$ROOT"/}" "$RST" "${DETAIL[i]:-}" ;;
      stalled) printf '  %s⏱ %s%s — %s\n' "$YEL" "${REPOS[$((i-1))]#"$ROOT"/}" "$RST" "${DETAIL[i]:-}" ;;
    esac
  done
fi

if (( SKIPPED > 0 )); then
  echo
  echo "${B}Skipped:${RST}"
  for ((i=1; i<=TOTAL; i++)); do
    [ "${STATUS[i]:-}" = "skipped" ] && printf '  %s– %s%s — %s\n' "$DIM" "${REPOS[$((i-1))]#"$ROOT"/}" "$RST" "${DETAIL[i]:-}"
  done
fi

if (( FAILED + STALLED > 0 )); then
  echo
  printf '%sRerun one with: %s --match <repo-name>%s\n' "$DIM" "${0##*/}" "$RST"
  exit 1
fi

if [ "$TRIM" -eq 1 ]; then
  printf '%sHistory window: at most %s %s (%s); shallower clones were not deepened; only the default branch is fetched.%s\n' \
    "$DIM" "$MONTHS" "$MONTH_NOUN" "$CUTOFF" "$RST"
fi

exit 0
