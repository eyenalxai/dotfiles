#!/usr/bin/env nu
# prune_archives.nu -- prune redundant yadm archive blobs while retaining milestone snapshots.
#
# yadm re-encrypts `.local/share/yadm/archive` on almost every commit, so the
# repository history accumulates one large blob per commit. This script rewrites
# the current branch so that every commit points at one of a small set of
# "milestone" snapshots, then garbage-collects the blobs that fall out of
# history.
#
# Milestones are chosen at run time from the snapshots that actually exist in the
# branch's history, so the script keeps working after it rewrites its own
# history. Only the currently checked-out branch is rewritten.

const ARCHIVE_PATH = ".local/share/yadm/archive"

# Retention tiers, oldest first. Each tier keeps the newest snapshot that is at
# least `age` old. The newest snapshot is always kept as "current".
const RETENTION = [
    { name: "6_months_old", age: 182day }
    { name: "1_month_old", age: 30day }
    { name: "2_weeks_old", age: 14day }
    { name: "1_week_old", age: 7day }
    { name: "3_days_old", age: 3day }
    { name: "2_days_old", age: 2day }
]

# Run git against an explicit --git-dir. --wrapped lets arbitrary git flags pass
# through without being interpreted by nushell.
def --wrapped git-repo [git_dir: path, ...args: string] {
    ^git --git-dir $git_dir ...$args
}

# Every commit reachable from HEAD, oldest first, as { commit, parents }.
def commit-history [git_dir: path] {
    git-repo $git_dir rev-list --reverse --topo-order --parents HEAD
    | lines
    | each {|line|
        let fields = ($line | split row " ")
        { commit: ($fields | first), parents: ($fields | skip 1) }
    }
}

# Every snapshot of the archive reachable from HEAD, oldest first.
def archive-versions [git_dir: path] {
    git-repo $git_dir log --reverse "--format=%H %ct" -- $ARCHIVE_PATH
    | lines
    | each {|line|
        let fields = ($line | split row " ")
        let commit = ($fields | first)
        {
            commit: $commit
            date: (($fields | get 1 | into int) * 1_000_000_000)
            blob: (git-repo $git_dir rev-parse $"($commit):($ARCHIVE_PATH)" | str trim)
        }
    }
}

# Choose the snapshots to keep, oldest first (largest index = newest).
def select-milestones [versions: list, now: int] {
    let per_tier = ($RETENTION | each {|tier|
        let cutoff = ($now - ($tier.age | into int))
        let eligible = ($versions | where date <= $cutoff)
        let chosen = (if ($eligible | is-empty) { $versions | first } else { $eligible | last })
        $chosen | insert tier $tier.name
    })
    let current = ($versions | last | insert tier "current")
    # Drop duplicate snapshots, keeping the newest tier that selected each blob.
    $per_tier
    | append $current
    | reduce --fold {} {|m, acc| $acc | upsert $m.blob $m }
    | values
    | sort-by date
}

# Map every commit to the blob of its newest milestone ancestor-or-self.
# Returns a list of "<commit>\t<blob>" lines for the index filter.
def build-blob-map [history: list, milestones: list] {
    let blobs = ($milestones | get blob)
    let seeds = ($milestones | enumerate | reduce --fold {} {|it, acc|
        $acc | upsert $it.item.commit $it.index
    })
    let result = ($history | reduce --fold { ranks: $seeds, lines: [] } {|commit, state|
        let parent_ranks = ($commit.parents | each {|parent| $state.ranks | get -o $parent } | compact)
        let inherited = (if ($parent_ranks | is-empty) { -1 } else { $parent_ranks | math max })
        let seed = ($seeds | get -o $commit.commit)
        let rank = (if ($seed == null) { $inherited } else { [$inherited $seed] | math max })
        let lines = (if ($rank < 0) {
            $state.lines
        } else {
            $state.lines | append $"($commit.commit)\t($blobs | get $rank)"
        })
        { ranks: ($state.ranks | upsert $commit.commit $rank), lines: $lines }
    })
    $result.lines
}

def human-size [path: path] {
    ^du -sh $path | str trim | split row (char tab) | first
}

def main [
    --execute           # Rewrite history. Without it, only a preview is shown.
    --git-dir: path     # Repository to operate on (defaults to the yadm repo).
] {
    let repo = ($git_dir | default ($env.HOME | path join ".local/share/yadm/repo.git"))
    let backup_dir = $"($repo).bak"

    # Locate the working tree so our cleanliness check and `git filter-branch`
    # look at the right place regardless of the caller's cwd. yadm stores it in
    # core.worktree; for a plain clone it is the parent of the `.git` directory.
    let configured = (git-repo $repo config --get core.worktree | complete)
    let work_tree = (if (($configured.exit_code == 0) and (not ((($configured.stdout | str trim)) | is-empty))) {
        $configured.stdout | str trim
    } else if (($repo | path basename) == ".git") {
        $repo | path dirname
    } else {
        null
    })

    print "=== 1. Analyzing yadm git history ==="
    let history = (commit-history $repo)
    let versions = (archive-versions $repo)
    if ($versions | is-empty) {
        error make { msg: $"No snapshots of ($ARCHIVE_PATH) found in HEAD's history." }
    }

    let now = ((date now) | into int)
    let milestones = (select-milestones $versions $now)
    let map_lines = (build-blob-map $history $milestones)

    let milestone_table = ($milestones | each {|m|
        {
            tier: $m.tier
            commit: ($m.commit | str substring 0..7)
            date: ($m.date | into datetime)
            size: ((git-repo $repo cat-file -s $m.blob | str trim | into int) | into filesize)
        }
    })
    print ($milestone_table | table)

    let archives_before = ($versions | length)
    let size_before = (human-size $repo)
    print $"History: ($history | length) commits, ($archives_before) archive snapshots."
    print $"Selected ($milestones | length) milestones \(($map_lines | length) commits mapped\)."

    if not $execute {
        print "\n=== Dry run ==="
        print "No changes made. Re-run with --execute to rewrite history."
        print "\nNote: only the current branch is rewritten; other branches and"
        print "remote-tracking refs keep their objects until the next push/gc."
        return
    }

    print "\n=== 2. Creating safety backup ==="
    if ($work_tree == null) {
        error make { msg: $"($repo) has no working tree; this script only rewrites non-bare repositories." }
    }
    let dirty = (git-repo $repo --work-tree $work_tree status --porcelain --untracked-files=no | str trim)
    if not ($dirty | is-empty) {
        error make { msg: $"Working tree ($work_tree) has uncommitted changes; commit or stash them before pruning." }
    }
    print -n $"(char cr)Backing up to ($backup_dir)..."
    rm -rf $backup_dir
    cp -r $repo $backup_dir
    print $"(char cr)(ansi erase_line_from_cursor_to_end)Backup created at ($backup_dir)."

    print "\n=== 3. Writing commit -> blob map ==="
    let map_file = (mktemp)
    $map_lines | str join (char nl) | append (char nl) | save --force $map_file
    print $"Wrote ($map_lines | length) entries to ($map_file)."

    print "\n=== 4. Rewriting current branch ==="
    let filter_script = 'blob=$(grep -m1 "^$GIT_COMMIT[[:space:]]" "$ARCHIVE_MAP" | cut -f2); if [ -n "$blob" ]; then git update-index --add --cacheinfo 100644 "$blob" .local/share/yadm/archive; else git rm --cached --ignore-unmatch .local/share/yadm/archive >/dev/null 2>&1 || true; fi'
    print -n $"(char cr)Rewriting history..."
    let filter_result = (with-env {
        GIT_DIR: ($repo | into string)
        GIT_WORK_TREE: ($work_tree | into string)
        FILTER_BRANCH_SQUELCH_WARNING: "1"
        ARCHIVE_MAP: $map_file
    } {
        ^git -C $work_tree filter-branch --force --index-filter $filter_script --prune-empty --tag-name-filter cat -- HEAD
    } | complete)
    if ($filter_result.exit_code != 0) {
        print $"(char cr)(ansi erase_line_from_cursor_to_end)"
        print $filter_result.stdout
        print $filter_result.stderr
        error make { msg: "git filter-branch failed; history was not rewritten." }
    }
    print $"(char cr)(ansi erase_line_from_cursor_to_end)History rewritten."

    # The archive at HEAD must still be the newest snapshot; if not, stop before
    # reclaiming anything so the backup is the only source of truth.
    let expected_blob = ($milestones | last | get blob)
    let rewritten_blob = (git-repo $repo rev-parse $"HEAD:($ARCHIVE_PATH)" | str trim)
    if ($rewritten_blob != $expected_blob) {
        error make { msg: $"Rewrite verification failed: HEAD archive is ($rewritten_blob), expected ($expected_blob). The backup is at ($backup_dir)." }
    }

    print "\n=== 5. Cleaning old references and repacking ==="
    print -n $"(char cr)Repacking repository and pruning unneeded objects..."
    git-repo $repo for-each-ref "--format=%(refname)" refs/original/
    | lines
    | where {|ref| not ($ref | is-empty) }
    | each {|ref| git-repo $repo update-ref -d $ref }
    git-repo $repo reflog expire --expire=now --all
    git-repo $repo gc --prune=now --quiet
    print $"(char cr)(ansi erase_line_from_cursor_to_end)Repacking complete."

    print "\n=== 6. Verification ==="
    print $"HEAD archive entry: (git-repo $repo ls-tree HEAD $ARCHIVE_PATH | str trim)"
    let archives_after = (git-repo $repo log --oneline -- $ARCHIVE_PATH | lines | length)
    let summary = [
        { metric: "Archive snapshots in history", before: ($archives_before | into string), after: ($archives_after | into string) }
        { metric: "Repository size on disk", before: $size_before, after: (human-size $repo) }
    ]
    print ($summary | table)
    rm -f $map_file
    print "\nDone. Force-push the rewritten branch when ready (e.g. `yadm push-all --force`)."
}
