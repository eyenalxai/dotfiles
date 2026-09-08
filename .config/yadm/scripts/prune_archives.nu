#!/usr/bin/env nu
# prune_archives.nu: Prune redundant yadm archive blobs while retaining milestone snapshots

def main [--execute] {
    let git_dir = ($env.HOME | path join ".local/share/yadm/repo.git")
    let backup_dir = ($env.HOME | path join ".local/share/yadm/repo.git.bak")
    let map_file = "/tmp/opencode/commit_archive_map.tsv"

    print "=== 1. Analyzing Yadm Git History ==="
    let all_commits = (^git --git-dir $git_dir rev-list --reverse HEAD | lines)
    let total_commits = ($all_commits | length)
    let size_before = (^du -sh $git_dir | split row "\t" | get 0 | str trim)
    let archives_before = (^git --git-dir $git_dir log --oneline -- .local/share/yadm/archive | lines | length)

    # Milestone snapshots defined by commit hashes in historical order
    let latest_archive_commit = (^git --git-dir $git_dir log -1 --format="%H" -- .local/share/yadm/archive | str trim)
    let milestones = [
        { name: '6_months_old', commit: 'c6fedf2e07d37364ac031386a0682991d8f1750b', label: 'Mar 13, 2026' },
        { name: '1_month_old',  commit: '32e09d61ea5a591de4d3bad306157f5870d28d52', label: 'Aug 01, 2026' },
        { name: '2_weeks_old',  commit: '14ac47c5174ff28f549975cfda1b21de55eb37e5', label: 'Aug 07, 2026' },
        { name: '1_week_old',   commit: '4a8ad3508227bc5ce00a93119bd38cb7d1f074e7', label: 'Sep 02, 2026' },
        { name: '3_days_old',   commit: '85c6d8ccbb7fb5d7f77a3b673418a340bb9d22fc', label: 'Sep 06, 2026' },
        { name: '2_days_old',   commit: '3f37fef7ca7aff1f292153b16d10cffbcc8f2613', label: 'Sep 07, 2026' },
        { name: 'current',      commit: $latest_archive_commit,                       label: 'Sep 09, 2026' },
    ]
    let archives_after = ($milestones | length)

    let ms_table = ($milestones | each { |m|
        let target_idx = ($all_commits | enumerate | where item == $m.commit | get 0.index)
        let blob = (^git --git-dir $git_dir rev-parse $"($m.commit):.local/share/yadm/archive" | str trim)
        let size_b = (^git --git-dir $git_dir cat-file -s $blob | str trim | into int)
        let size_kb = ($size_b / 1024 | math round --precision 1)
        $m | insert target_idx $target_idx | insert blob $blob | insert size_kb $"($size_kb) KB"
    })

    print ($ms_table | select name label commit target_idx size_kb blob | table)

    # Build chronological commit -> blob mapping
    let tsv_lines = ($all_commits | enumerate | each { |it|
        let curr_idx = $it.index
        let candidates = ($ms_table | where target_idx <= $curr_idx)
        let active_blob = if ($candidates | length) > 0 {
            $candidates | last | get blob
        } else {
            ""
        }
        $"($it.item)\t($active_blob)"
    })

    mkdir "/tmp/opencode"
    $tsv_lines | str join (char nl) | save --force $map_file
    print $"Mapped ($tsv_lines | length) total repository commits."

    if not $execute {
        print "\n=== Before & After (Dry-Run Preview) ==="
        let preview_summary = [
            { metric: "Archive snapshots in history", before: ($archives_before | into string), after: ($archives_after | into string) },
            { metric: "Repository size on disk",      before: $size_before,                     after: "~14M (estimated)" },
        ]
        print ($preview_summary | table)
        print "\nDry-run complete. Run with --execute to perform the rewrite."
        return
    }

    print $"\n=== 2. Creating Full Safety Backup at ($backup_dir) ==="
    rm -rf $backup_dir
    cp -r $git_dir $backup_dir
    print "Backup created successfully."

    print "\n=== 3. Rewriting History with git filter-branch ==="
    let filter_cmd = (
        'target_blob=$(grep "^$GIT_COMMIT\t" /tmp/opencode/commit_archive_map.tsv | cut -f2); ' +
        'if [ -n "$target_blob" ]; then ' +
        '    git update-index --add --cacheinfo 100644 "$target_blob" .local/share/yadm/archive; ' +
        'else ' +
        '    git rm --cached --ignore-unmatch .local/share/yadm/archive >/dev/null 2>&1; ' +
        'fi'
    )

    with-env {
        GIT_DIR: $git_dir,
        FILTER_BRANCH_SQUELCH_WARNING: "1"
    } {
        ^git filter-branch --force --index-filter $filter_cmd --prune-empty --tag-name-filter cat -- --all
    }

    print "\n=== 4. Cleaning Old References and Repacking ==="
    let original_refs = (^git --git-dir $git_dir for-each-ref --format="%(refname)" refs/original/ | lines)
    for ref in $original_refs {
        if ($ref | str length) > 0 {
            ^git --git-dir $git_dir update-ref -d $ref
        }
    }
    ^git --git-dir $git_dir reflog expire --expire=now --all
    ^git --git-dir $git_dir gc --prune=now --aggressive

    print "\n=== 5. Verification ==="
    let archive_log = (^git --git-dir $git_dir log --format="%h %ci %s" -- .local/share/yadm/archive | lines)
    print "Commits modifying .local/share/yadm/archive in new history:"
    for line in $archive_log {
        print $"  ($line)"
    }

    let head_blob = (^git --git-dir $git_dir ls-tree HEAD .local/share/yadm/archive | str trim)
    print $"\nHEAD archive entry:\n  ($head_blob)"

    let actual_archives_after = (^git --git-dir $git_dir log --oneline -- .local/share/yadm/archive | lines | length)
    let size_after = (^du -sh $git_dir | split row "\t" | get 0 | str trim)

    print "\n=== 6. Before & After Summary ==="
    let final_summary = [
        { metric: "Archive snapshots in history", before: ($archives_before | into string), after: ($actual_archives_after | into string) },
        { metric: "Repository size on disk",      before: $size_before,                     after: $size_after },
    ]
    print ($final_summary | table)

    print "\n✓ Pruning complete! You can now force-push with: yadm push --force origin main"
}
