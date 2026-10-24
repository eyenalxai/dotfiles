#!/usr/bin/env bash
# List pending package updates as TSV: repository, package, installed, candidate.
#
#   updates.sh --system [--force]   official repositories (fresh sync DB)
#   updates.sh --aur    [--force]   AUR packages (yay or paru)
#   updates.sh --last-upgrade       epoch of the last package upgrade
#
# Every monitor runs its own bar widget, so two checks can start at the same
# time. A short cache plus a per-source lock makes them share one network
# round-trip instead of hammering the mirrors in parallel. --force skips the
# cache for a user-requested refresh.

set -uo pipefail

CACHE_TTL="${UPDATES_CACHE_TTL:-90}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-updates"
mkdir -p "$STATE_DIR" || exit 1

mode=""
force=0
for arg in "$@"; do
  case "$arg" in
    --system | --aur | --last-upgrade) mode="$arg" ;;
    --force) force=1 ;;
    *)
      echo "usage: ${0##*/} --system|--aur|--last-upgrade [--force]" >&2
      exit 2
      ;;
  esac
done

if [[ -z $mode ]]; then
  echo "usage: ${0##*/} --system|--aur|--last-upgrade [--force]" >&2
  exit 2
fi

# The last ALPM "upgraded" entry is the last time packages actually changed.
# Hooks and sync runs do not count, and the install date in the local DB is
# the original install, not the latest upgrade.
if [[ $mode == "--last-upgrade" ]]; then
  timestamp=$(tac /var/log/pacman.log 2>/dev/null |
    grep -m1 -E '^\[[^]]+\] \[ALPM\] (upgraded|downgraded|reinstalled)' |
    sed -E 's/^\[([^]]+)\].*/\1/')

  if [[ -n $timestamp ]]; then
    epoch=$(date -d "$timestamp" +%s 2>/dev/null || true)
    if [[ -n $epoch ]]; then
      printf '%s\n' "$epoch"
      exit 0
    fi
  fi

  # Rotated or missing log: the package metadata write time is the same
  # moment, so use the newest one.
  newest=$(find /var/lib/pacman/local -maxdepth 2 -name desc -printf '%T@\n' 2>/dev/null |
    sort -n | tail -n 1 | cut -d. -f1)
  [[ -n $newest ]] && printf '%s\n' "$newest"
  exit 0
fi

source="${mode#--}"
cache="$STATE_DIR/$source.tsv"
lock="$STATE_DIR/$source.lock"
tmp="$STATE_DIR/$source.tsv.$$"

cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

emit_cache() { [[ -f $cache ]] && cat "$cache"; }

# Serialise checks per source. A widget that arrives while another is already
# fetching waits for it, then reads the cache that check writes.
exec 9>"$lock" || exit 1
if ! flock -w 120 9; then
  emit_cache
  exit 0
fi

if ((!force)) && [[ -f $cache ]]; then
  age=$(($(date +%s) - $(stat -c %Y "$cache")))
  if ((age >= 0 && age < CACHE_TTL)); then
    emit_cache
    exit 0
  fi
fi

# checkupdates talks to the mirrors through a throwaway sync database and
# exits 2 when the system is up to date. pacman -Qu is the fallback when
# pacman-contrib is absent; it reads the last synced database.
system_updates() {
  local err="$STATE_DIR/system.err" rc
  if command -v checkupdates >/dev/null 2>&1; then
    timeout 180 checkupdates --nocolor 2>"$err"
    rc=$?
    ((rc == 0 || rc == 2)) && return 0
  else
    timeout 180 pacman -Qu 2>"$err"
    rc=$?
    ((rc == 0 || rc == 1)) && return 0
  fi

  cat "$err" >&2
  return 1
}

aur_updates() {
  local helper="" err="$STATE_DIR/aur.err" rc output
  for candidate in yay paru; do
    if command -v "$candidate" >/dev/null 2>&1; then
      helper="$candidate"
      break
    fi
  done

  if [[ -z $helper ]]; then
    echo "No AUR helper found. Install yay or paru." >&2
    return 1
  fi

  output=$(timeout 120 "$helper" -Qua 2>"$err")
  rc=$?
  if [[ -n $output ]]; then printf '%s\n' "$output"; fi
  # yay and paru return 1 when no foreign package has an update. A failed AUR
  # query also returns 1, so only an empty stderr counts as "up to date".
  ((rc == 0)) && return 0
  ((rc == 1)) && [[ ! -s $err ]] && return 0

  cat "$err" >&2
  return 1
}

emit_updates() {
  local line package installed arrow candidate repo
  declare -A repositories=()

  if [[ $source == "system" ]]; then
    while IFS=$'\t' read -r package repo; do
      repositories["$package"]="$repo"
    done < <(expac -S '%n\t%r' 2>/dev/null)
  fi

  while IFS= read -r line; do
    [[ -n $line ]] || continue
    read -r package installed arrow candidate <<<"$line"
    [[ $arrow == "->" && -n ${candidate:-} ]] || continue

    if [[ $source == "system" ]]; then
      repo="${repositories[$package]:-system}"
    else
      repo="AUR"
    fi

    printf '%s\t%s\t%s\t%s\n' "$repo" "$package" "$installed" "$candidate"
  done
}

if [[ $mode == "--system" ]]; then
  if ! system_updates | emit_updates >"$tmp"; then
    exit 1
  fi
else
  if ! aur_updates | emit_updates >"$tmp"; then
    exit 1
  fi
fi

mv -f "$tmp" "$cache" || exit 1
cat "$cache"
