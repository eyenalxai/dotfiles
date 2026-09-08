# nu-version: 0.102.0

module yadm-completion-utils {
  export const YADM_SKIPABLE_FLAGS = ['-v', '--version', '-h', '--help', '-p', '--paginate', '-P', '--no-pager', '--no-replace-objects', '--bare', '-Y']

  # Helper function to append token if non-empty
  def append-non-empty [token: string]: list<string> -> list<string> {
    if ($token | is-empty) { $in } else { $in | append $token }
  }

  # Split a string to list of args, taking quotes into account.
  # Code is copied and modified from https://github.com/nushell/nushell/issues/14582#issuecomment-2542596272
  export def args-split []: string -> list<string> {
    # Define our states
    const STATE_NORMAL = 0
    const STATE_IN_SINGLE_QUOTE = 1
    const STATE_IN_DOUBLE_QUOTE = 2
    const STATE_ESCAPE = 3
    const WHITESPACES = [" " "\t" "\n" "\r"]

    # Initialize variables
    mut state = $STATE_NORMAL
    mut current_token = ""
    mut result: list<string> = []
    mut prev_state = $STATE_NORMAL

    # Process each character
    for char in ($in | split chars) {
      if $state == $STATE_ESCAPE {
        # Handle escaped character
        $current_token = $current_token + $char
        $state = $prev_state
      } else if $char == '\' {
        # Enter escape state
        $prev_state = $state
        $state = $STATE_ESCAPE
      } else if $state == $STATE_NORMAL {
        if $char == "'" {
          $state = $STATE_IN_SINGLE_QUOTE
        } else if $char == '"' {
          $state = $STATE_IN_DOUBLE_QUOTE
        } else if ($char in $WHITESPACES) {
          # Whitespace in normal state means token boundary
          $result = $result | append-non-empty $current_token
          $current_token = ""
        } else {
          $current_token = $current_token + $char
        }
      } else if $state == $STATE_IN_SINGLE_QUOTE {
        if $char == "'" {
          $state = $STATE_NORMAL
        } else {
          $current_token = $current_token + $char
        }
      } else if $state == $STATE_IN_DOUBLE_QUOTE {
        if $char == '"' {
          $state = $STATE_NORMAL
        } else {
          $current_token = $current_token + $char
        }
      }
    }
    # Handle the last token
    $result = $result | append-non-empty $current_token
    # Return the result
    $result
  }

  # Get changed files which can be restored by `git checkout --`
  export def get-changed-files []: nothing -> list<string> {
    ^yadm status -uno --porcelain=2 | lines
    | where $it =~ '^1 [.MD]{2}'
    | each { split row ' ' -n 9 | last }
  }

  # Get files which can be retrieved from a branch/commit by `git checkout <tree-ish>`
  export def get-checkoutable-files []: nothing -> list<string> {
    # Relevant statuses are .M", "MM", "MD", ".D", "UU"
    ^yadm status -uno --porcelain=2 | lines
    | where $it =~ '^1 ([.MD]{2}|UU)'
    | each { split row ' ' -n 9 | last }
  }

  export def get-all-yadm-local-refs []: nothing -> list<record<ref: string, obj: string, upstream: string, subject: string>> {
    ^yadm for-each-ref --format '%(refname:lstrip=2)%09%(objectname:short)%09%(upstream:remotename)%(upstream:track)%09%(contents:subject)' refs/heads | lines | parse "{ref}\t{obj}\t{upstream}\t{subject}"
  }

  export def get-all-yadm-remote-refs []: nothing -> list<record<ref: string, obj: string, subject: string>> {
    ^yadm for-each-ref --format '%(refname:lstrip=2)%09%(objectname:short)%09%(contents:subject)' refs/remotes | lines | parse "{ref}\t{obj}\t{subject}"
  }

  # Get local branches, remote branches which can be passed to `git merge`
  export def get-mergable-sources []: nothing -> list<record<value: string, description: string>> {
    let local = get-all-yadm-local-refs | each {|x| {value: $x.ref description: $'Branch, Local, ($x.obj) ($x.subject), (if ($x.upstream | is-not-empty) { $x.upstream } else { "no upstream" } )'} } | insert style 'light_blue'
    let remote = get-all-yadm-remote-refs | each {|x| {value: $x.ref description: $'Branch, Remote, ($x.obj) ($x.subject)'} } | insert style 'blue_italic'
    $local | append $remote
  }
}

def "nu-complete yadm available upstream" [] {
  ^yadm for-each-ref --format '%(refname:short)' refs/heads refs/remotes | lines
}

def "nu-complete yadm remotes" [] {
  let out = (do { ^yadm remote --verbose } | complete)
  if $out.exit_code != 0 or ($out.stdout | is-empty) { return [] }
  $out.stdout
  | lines
  | parse --regex '(?P<value>\S+)\s+(?P<description>\S+)'
  | uniq-by value # Deduplicate where fetch and push remotes are the same
}

def "nu-complete yadm log" [] {
  ^yadm log --pretty=%h | lines | each { |line| $line | str trim }
}

# Yield all existing commits in descending chronological order.
def "nu-complete yadm commits all" [] {
  ^yadm rev-list --all --remotes --pretty=oneline | lines | parse "{value} {description}"
}

# Yield commits of current branch only. This is useful for e.g. cut points in
# `git rebase`.
def "nu-complete yadm commits current branch" [] {
  ^yadm log --pretty="%h %s" | lines | parse "{value} {description}"
}

# Yield local branches like `main`, `feature/typo_fix`
def "nu-complete yadm local branches" [] {
  ^yadm for-each-ref --format '%(refname:short)' refs/heads | lines
}

# Yield remote branches like `origin/main`, `upstream/feature-a`
def "nu-complete yadm remote branches with prefix" [] {
  ^yadm for-each-ref --format='%(refname:lstrip=2)' refs/remotes | lines
}

# Yield local and remote branch names which can be passed to `git merge`
def "nu-complete yadm mergable sources" [] {
  use yadm-completion-utils *
  let branches = get-mergable-sources
  {
    options: {
        case_sensitive: false,
        completion_algorithm: prefix,
        sort: false,
    },
    completions: $branches
  }
}

def "nu-complete yadm switch" [] {
  use yadm-completion-utils *
  let branches = get-mergable-sources
  {
    options: {
        case_sensitive: false,
        completion_algorithm: prefix,
        sort: false,
    },
    completions: $branches
  }
}

def "nu-complete yadm checkout" [context: string, position?:int] {
  use yadm-completion-utils *
  let preceding = $context | str substring ..$position
  # See what user typed before, like 'git checkout a-branch a-path'.
  # We exclude some flags from previous tokens, to detect if  a branch name has been used as the first argument.
  # FIXME: This method is still naive, though.
  let prev_tokens = $preceding | str trim | args-split | where ($it not-in $YADM_SKIPABLE_FLAGS)
  # In these scenarios, we suggest only file paths, not branch:
  # - After '--'
  # - First arg is a branch
  # If before '--' is just 'git checkout' (or its alias), we suggest "dirty" files only (user is about to reset file).
  if $prev_tokens.2? == '--' {
    return (get-changed-files)
  }
  if '--' in $prev_tokens {
    return (get-checkoutable-files)
  }
  # Already typed first argument.
  if ($prev_tokens | length) > 2 and $preceding ends-with ' ' {
    # If we are creating a new branch, we may want to specify a start point
    if ("-b" not-in $prev_tokens) and ("-B" not-in $prev_tokens) and ("--orphan" not-in $prev_tokens) {
      return (get-checkoutable-files)
    }
  }
  # The first argument can be local branches, remote branches, files and commits
  # Get local and remote branches
  let branches = get-mergable-sources
  let files = (get-checkoutable-files) | wrap value | insert description 'File' | insert style green
  let commits = ^yadm rev-list -n 400 --remotes --oneline | lines | split column -n 2 ' ' value description | upsert description {|x| $'Commit, ($x.value) ($x.description)' } | insert style 'light_cyan_dimmed'
  {
    options: {
        case_sensitive: false,
        completion_algorithm: prefix,
        sort: false,
    },
    completions: [...$branches, ...$files, ...$commits]
  }
}

# Arguments to `git rebase --onto <arg1> <arg2>`
def "nu-complete yadm rebase" [] {
  (nu-complete yadm local branches)
  | parse "{value}"
  | insert description "local branch"
  | append (nu-complete yadm remote branches with prefix
            | parse "{value}"
            | insert description "remote branch")
  | append (nu-complete yadm commits all)
}

def "nu-complete yadm stash-list" [] {
  ^yadm stash list | lines | parse "{value}: {description}"
}

def "nu-complete yadm tags" [] {
  ^yadm tag --no-color | lines
}

# See `man git-status` under "Short Format"
# This is incomplete, but should cover the most common cases.
const short_status_descriptions = {
  ".D": "Deleted"
  ".M": "Modified"
  "!" : "Ignored"
  "?" : "Untracked"
  "AU": "Staged, not merged"
  "MD": "Some modifications staged, file deleted in work tree"
  "MM": "Some modifications staged, some modifications untracked"
  "R.": "Renamed"
  "UU": "Both modified (in merge conflict)"
}

def "nu-complete yadm files" [path?: string] {
  let relevant_statuses = ["?", ".M", "MM", "MD", ".D", "UU"]
  let status_output = (do { ^yadm status -uno --porcelain=2 } | complete)
  if $status_output.exit_code != 0 or ($status_output.stdout | is-empty) {
    return null
  }
  let res = (
    $status_output.stdout
    | lines
    | first 300
    | each { |$it|
      if $it starts-with "1 " {
        $it | parse --regex '1 (?P<short_status>\S+) (?:\S+\s?){6} (?P<value>.+)'
      } else if $it starts-with "2 " {
        $it | parse --regex '2 (?P<short_status>\S+) (?:\S+\s?){6} (?P<value>.+)'
      } else if $it starts-with "u " {
        $it | parse --regex 'u (?P<short_status>\S+) (?:\S+\s?){8} (?P<value>.+)'
      } else if $it starts-with "? " {
        $it | parse --regex '(?P<short_status>.{1}) (?P<value>.+)'
      } else {
        { short_status: 'unknown', value: $it }
      }
    }
    | flatten
    | where $it.short_status in $relevant_statuses
    | update value { |row| if ($row.value | str contains " ") { $"`($row.value)`" } else { $row.value } }
    | insert "description" { |e| $short_status_descriptions | get -o $e.short_status | default "Changed" }
  )
  if ($res | is-empty) {
    null
  } else {
    $res
  }
}

def "nu-complete yadm built-in-refs" [] {
  [HEAD FETCH_HEAD ORIG_HEAD]
}

def "nu-complete yadm refs" [] {
  nu-complete yadm local branches
  | parse "{value}"
  | insert description Branch
  | append (nu-complete yadm remotes | parse '{value}' | insert description 'Remote branch')
  | append (nu-complete yadm tags | parse "{value}" | insert description Tag)
  | append (nu-complete yadm built-in-refs)
}

def "nu-complete yadm files-or-refs" [] {
  {
    options: { sort: false },
    completions: (
      nu-complete yadm files | where description == "Modified" | select value description
      | append (nu-complete yadm local branches | parse '{value}' | insert description 'Local branch')
      | append (nu-complete yadm built-in-refs | parse '{value}' | insert description 'Built-in Refs')
      | append (nu-complete yadm tags | parse '{value}' | insert description Tag)
      | append (nu-complete yadm remotes | get 'value' | parse '{value}' | insert description 'Remote branch')
    )
  }
}

def "nu-complete yadm aliases" [] {
  ^yadm config --get-regexp ^alias\.
  | lines
  | parse "alias.{value} {description}"
}

def "nu-complete yadm git-subcommands" [] {
  let out = (do { ^yadm help -a } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines | where $it starts-with "   " | parse -r '\s*(?P<value>[^ ]+) \s*(?P<description>\w.*)'
    | append (nu-complete yadm aliases)
    | uniq-by value
  } else {
    []
  }
}

def "nu-complete yadm subcommands" [] {
  let yadm_cmds = [
    { value: "add", description: "Add file contents to the index" },
    { value: "alt", description: "Create links for alternates" },
    { value: "bootstrap", description: "Execute bootstrap program" },
    { value: "branch", description: "List, create, or delete branches" },
    { value: "checkout", description: "Switch branches or restore working tree files" },
    { value: "clone", description: "Clone an existing repository" },
    { value: "commit", description: "Record changes to the repository" },
    { value: "config", description: "Configure a yadm setting" },
    { value: "decrypt", description: "Decrypt files" },
    { value: "diff", description: "Show changes between commits, commit and working tree, etc" },
    { value: "encrypt", description: "Encrypt files" },
    { value: "enter", description: "Run sub-shell with GIT variables set" },
    { value: "fetch", description: "Download objects and refs from another repository" },
    { value: "git-crypt", description: "Run git-crypt commands for yadm repo" },
    { value: "gitconfig", description: "Pass options to git config for yadm repo" },
    { value: "help", description: "Print a summary of yadm commands" },
    { value: "init", description: "Initialize an empty repository" },
    { value: "introspect", description: "Report internal information (commands, configs, repo, switches)" },
    { value: "list", description: "List tracked files" },
    { value: "log", description: "Show commit logs" },
    { value: "merge", description: "Join two or more development histories together" },
    { value: "perms", description: "Fix perms for private files" },
    { value: "pull", description: "Fetch from and integrate with another repository or branch" },
    { value: "push", description: "Update remote refs along with associated objects" },
    { value: "rebase", description: "Reapply commits on top of another base tip" },
    { value: "remote", description: "Manage set of tracked repositories" },
    { value: "reset", description: "Reset current HEAD to the specified state" },
    { value: "restore", description: "Restore working tree files" },
    { value: "rm", description: "Remove files from the working tree and from the index" },
    { value: "stash", description: "Stash the changes in a dirty working directory away" },
    { value: "status", description: "Show the working tree status" },
    { value: "switch", description: "Switch branches" },
    { value: "transcrypt", description: "Run transcrypt commands for yadm repo" },
    { value: "upgrade", description: "Upgrade yadm to latest version" },
    { value: "version", description: "Print yadm version" },
  ]
  $yadm_cmds | append (nu-complete yadm git-subcommands) | uniq-by value
}

def "nu-complete yadm tracked files" [] {
  let out = (do { ^yadm list } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines
  } else {
    []
  }
}

def "nu-complete yadm config names" [] {
  let out = (do { ^yadm introspect configs } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines
  } else {
    []
  }
}

def "nu-complete yadm introspect categories" [] {
  [
    { value: "commands", description: "All supported yadm commands" },
    { value: "configs", description: "All supported yadm configuration names" },
    { value: "repo", description: "Path to yadm repository" },
    { value: "switches", description: "Supported command line switches" },
  ]
}

def "nu-complete yadm add" [context: string = "", position: int = 0] {
  let modified = (
    try {
      let status_out = (do { ^yadm status -uno --porcelain=2 } | complete)
      if $status_out.exit_code == 0 and ($status_out.stdout | is-not-empty) {
        $status_out.stdout
        | lines
        | parse --regex '^[12] (?P<status>\S+) (?:\S+\s?){6} (?P<value>.+)'
        | insert description "Modified"
        | select value description
      } else {
        []
      }
    } catch {
      []
    }
  )

  let last_word = ($context | str substring ..$position | split words | last? | default "")
  let path_completions = (
    try {
      $last_word | commandline complete --type path | each { |p| { value: $p, description: "Path" } }
    } catch {
      []
    }
  )

  let combined = ($modified | append $path_completions | uniq-by value)
  if ($combined | is-empty) {
    null
  } else {
    $combined
  }
}

def "nu-complete yadm pull rebase" [] {
  ["false","true","merges","interactive"]
}

def "nu-complete yadm merge strategies" [] {
  ['ort', 'octopus']
}

def "nu-complete yadm merge strategy options" [] {
  ['ours', 'theirs']
}


# Check out git branches and files
export extern "yadm checkout" [
  ...targets: string@"nu-complete yadm checkout"   # name of the branch or files to checkout
  --conflict: string                              # conflict style (merge or diff3)
  --detach(-d)                                    # detach HEAD at named commit
  --force(-f)                                     # force checkout (throw away local modifications)
  --guess                                         # second guess 'git checkout <no-such-branch>' (default)
  --ignore-other-worktrees                        # do not check if another worktree is holding the given ref
  --ignore-skip-worktree-bits                     # do not limit pathspecs to sparse entries only
  --merge(-m)                                     # perform a 3-way merge with the new branch
  --orphan: string                                # new unparented branch
  --ours(-2)                                      # checkout our version for unmerged files
  --overlay                                       # use overlay mode (default)
  --overwrite-ignore                              # update ignored files (default)
  --patch(-p)                                     # select hunks interactively
  --pathspec-from-file: string                    # read pathspec from file
  --progress                                      # force progress reporting
  --quiet(-q)                                     # suppress progress reporting
  --recurse-submodules                            # control recursive updating of submodules
  --theirs(-3)                                    # checkout their version for unmerged files
  --track(-t)                                     # set upstream info for new branch
  -b                                              # create and checkout a new branch
  -B: string                                      # create/reset and checkout a branch
  -l                                              # create reflog for new branch
]

export extern "yadm reset" [
  ...targets: string@"nu-complete yadm checkout"      # name of commit, branch, or files to reset to
  --hard                                          # reset HEAD, index and working tree
  --keep                                          # reset HEAD but keep local changes
  --merge                                         # reset HEAD, index and working tree
  --mixed                                         # reset HEAD and index
  --patch(-p)                                     # select hunks interactively
  --quiet(-q)                                     # be quiet, only report errors
  --soft                                          # reset only HEAD
  --pathspec-from-file: string                    # read pathspec from file
  --pathspec-file-nul                             # with --pathspec-from-file, pathspec elements are separated with NUL character
  --no-refresh                                    # skip refreshing the index after reset
  --recurse-submodules: string                    # control recursive updating of submodules
  --no-recurse-submodules                         # don't recurse into submodules
]

# Download objects and refs from another repository
export extern "yadm fetch" [
  repository?: string@"nu-complete yadm remotes" # name of the branch to fetch
  --all                                         # Fetch all remotes
  --append(-a)                                  # Append ref names and object names to .git/FETCH_HEAD
  --atomic                                      # Use an atomic transaction to update local refs.
  --depth: int                                  # Limit fetching to n commits from the tip
  --deepen: int                                 # Limit fetching to n commits from the current shallow boundary
  --shallow-since: string                       # Deepen or shorten the history by date
  --shallow-exclude: string                     # Deepen or shorten the history by branch/tag
  --unshallow                                   # Fetch all available history
  --update-shallow                              # Update .git/shallow to accept new refs
  --negotiation-tip: string                     # Specify which commit/glob to report while fetching
  --negotiate-only                              # Do not fetch, only print common ancestors
  --dry-run                                     # Show what would be done
  --write-fetch-head                            # Write fetched refs in FETCH_HEAD (default)
  --no-write-fetch-head                         # Do not write FETCH_HEAD
  --force(-f)                                   # Always update the local branch
  --keep(-k)                                    # Keep downloaded pack
  --multiple                                    # Allow several arguments to be specified
  --auto-maintenance                            # Run 'git maintenance run --auto' at the end (default)
  --no-auto-maintenance                         # Don't run 'git maintenance' at the end
  --auto-gc                                     # Run 'git maintenance run --auto' at the end (default)
  --no-auto-gc                                  # Don't run 'git maintenance' at the end
  --write-commit-graph                          # Write a commit-graph after fetching
  --no-write-commit-graph                       # Don't write a commit-graph after fetching
  --prefetch                                    # Place all refs into the refs/prefetch/ namespace
  --prune(-p)                                   # Remove obsolete remote-tracking references
  --prune-tags(-P)                              # Remove any local tags that do not exist on the remote
  --no-tags(-n)                                 # Disable automatic tag following
  --refmap: string                              # Use this refspec to map the refs to remote-tracking branches
  --tags(-t)                                    # Fetch all tags
  --recurse-submodules: string                  # Fetch new commits of populated submodules (yes/on-demand/no)
  --jobs(-j): int                               # Number of parallel children
  --no-recurse-submodules                       # Disable recursive fetching of submodules
  --set-upstream                                # Add upstream (tracking) reference
  --submodule-prefix: string                    # Prepend to paths printed in informative messages
  --upload-pack: string                         # Non-default path for remote command
  --quiet(-q)                                   # Silence internally used git commands
  --verbose(-v)                                 # Be verbose
  --progress                                    # Report progress on stderr
  --server-option(-o): string                   # Pass options for the server to handle
  --show-forced-updates                         # Check if a branch is force-updated
  --no-show-forced-updates                      # Don't check if a branch is force-updated
  -4                                            # Use IPv4 addresses, ignore IPv6 addresses
  -6                                            # Use IPv6 addresses, ignore IPv4 addresses
]

# Yield local branches and (if remote is specified) remote branches with colon prefix
def "nu-complete yadm push" [context: string, position: int] {
  use yadm-completion-utils *
  let preceding = $context | str substring ..$position
  let tokens = $preceding | str trim | args-split | where ($it not-in $YADM_SKIPABLE_FLAGS)

  # Check if we have a remote argument (2nd token, 1st is 'git', 2nd is 'push', 3rd is remote)
  # BUT, args-split might be different depending on how it's called.
  # "git push origin" -> ["git", "push", "origin"]
  # If we have at least 3 tokens, the 3rd one IS likely the remote.
  # We should double check if the 3rd token is actually a remote.
  
  mut remote = ""
  if ($tokens | length) >= 3 {
    $remote = $tokens.2
  }

  let local_branches = (nu-complete yadm local branches)
  
  if ($remote | is-empty) {
    return $local_branches
  }

  # If we have a remote, find branches for that remote
  # Use plumbing command to get remote branches, excluding HEAD
  let remote_branches = (^yadm for-each-ref --format='%(refname:lstrip=3)' $'refs/remotes/($remote)' | lines | where $it != 'HEAD')
  
  # Prefix them with :
  let deletion_candidates = ($remote_branches | each { |it| $":($it)" })

  $local_branches | append $deletion_candidates
}

# Push changes
export extern "yadm push" [
  remote?: string@"nu-complete yadm remotes",         # the name of the remote
  ...refs: string@"nu-complete yadm push"             # the branch / refspec
  --all                                              # push all refs
  --atomic                                           # request atomic transaction on remote side
  --delete(-d)                                       # delete refs
  --dry-run(-n)                                      # dry run
  --exec: string                                     # receive pack program
  --follow-tags                                      # push missing but relevant tags
  --force-with-lease                                 # require old value of ref to be at this value
  --force(-f)                                        # force updates
  --ipv4(-4)                                         # use IPv4 addresses only
  --ipv6(-6)                                         # use IPv6 addresses only
  --mirror                                           # mirror all refs
  --no-verify                                        # bypass pre-push hook
  --porcelain                                        # machine-readable output
  --progress                                         # force progress reporting
  --prune                                            # prune locally removed refs
  --push-option(-o): string                          # option to transmit
  --quiet(-q)                                        # be more quiet
  --receive-pack: string                             # receive pack program
  --recurse-submodules: string                       # control recursive pushing of submodules
  --repo: string                                     # repository
  --set-upstream(-u)                                 # set upstream for git pull/status
  --signed: string                                   # GPG sign the push
  --tags                                             # push tags (can't be used with --all or --mirror)
  --thin                                             # use thin pack
  --verbose(-v)                                      # be more verbose
]

# Pull changes
export extern "yadm pull" [
  remote?: string@"nu-complete yadm remotes",         # the name of the remote
  ...refs: string@"nu-complete yadm local branches",  # the branch / refspec
  --rebase(-r): string@"nu-complete yadm pull rebase",    # rebase current branch on top of upstream after fetching
  --quiet(-q)                                        # suppress output during transfer and merge
  --verbose(-v)                                      # be more verbose
  --commit                                           # perform the merge and commit the result
  --no-commit                                        # perform the merge but do not commit the result
  --edit(-e)                                         # edit the merge commit message
  --no-edit                                          # use the auto-generated merge commit message
  --cleanup: string                                  # specify how to clean up the merge commit message
  --ff                                               # fast-forward if possible
  --no-ff                                            # create a merge commit in all cases
  --gpg-sign(-S)                                     # GPG-sign the resulting merge commit
  --no-gpg-sign                                      # do not GPG-sign the resulting merge commit
  --log: int                                         # include log messages from merged commits
  --no-log                                           # do not include log messages from merged commits
  --signoff                                          # add Signed-off-by trailer
  --no-signoff                                       # do not add Signed-off-by trailer
  --stat(-n)                                         # show a diffstat at the end of the merge
  --no-stat                                          # do not show a diffstat at the end of the merge
  --squash                                           # produce working tree and index state as if a merge happened
  --no-squash                                        # perform the merge and commit the result
  --verify                                           # run pre-merge and commit-msg hooks
  --no-verify                                        # do not run pre-merge and commit-msg hooks
  --strategy(-s): string                             # use the given merge strategy
  --strategy-option(-X): string                      # pass merge strategy-specific option
  --verify-signatures                                # verify the tip commit of the side branch being merged
  --no-verify-signatures                             # do not verify the tip commit of the side branch being merged
  --summary                                          # show a summary of the merge
  --no-summary                                       # do not show a summary of the merge
  --autostash                                        # create a temporary stash entry before the operation
  --no-autostash                                     # do not create a temporary stash entry before the operation
  --allow-unrelated-histories                        # allow merging histories without a common ancestor
  --no-rebase                                        # do not rebase the current branch on top of the upstream branch
  --all                                              # fetch all remotes
  --append(-a)                                       # append fetched refs to existing contents of FETCH_HEAD
  --atomic                                           # use an atomic transaction to update local refs
  --depth: int                                       # limit fetching to the specified number of commits
  --deepen: int                                      # deepen the history by the specified number of commits
  --shallow-since: string                            # deepen or shorten the history since a specified date
  --shallow-exclude: string                          # exclude commits reachable from a specified branch or tag
  --unshallow                                        # convert a shallow repository to a complete one
  --update-shallow                                   # update .git/shallow with new refs
  --tags(-t)                                         # fetch all tags from the remote
  --jobs(-j): int                                    # number of parallel children for fetching
  --set-upstream                                     # add upstream (tracking) reference
  --upload-pack: string                              # specify non-default path for upload-pack on the remote
  --progress                                         # force progress status even if stderr is not a terminal
  --server-option(-o): string                        # transmit the given string to the server
]

# Switch between branches and commits
export extern "yadm switch" [
  switch?: string@"nu-complete yadm switch"        # name of branch to switch to
  start_point?: string@"nu-complete yadm rebase"   # name of the start point
  --create(-c)                                    # create a new branch
  --detach(-d): string@"nu-complete yadm log"      # switch to a commit in a detached state
  --force-create(-C): string                      # forces creation of new branch, if it exists then the existing branch will be reset to starting point
  --force(-f)                                     # alias for --discard-changes
  --guess                                         # if there is no local branch which matches then name but there is a remote one then this is checked out
  --ignore-other-worktrees                        # switch even if the ref is held by another worktree
  --merge(-m)                                     # attempts to merge changes when switching branches if there are local changes
  --no-guess                                      # do not attempt to match remote branch names
  --no-progress                                   # do not report progress
  --no-recurse-submodules                         # do not update the contents of sub-modules
  --no-track                                      # do not set "upstream" configuration
  --orphan: string                                # create a new orphaned branch
  --progress                                      # report progress status
  --quiet(-q)                                     # suppress feedback messages
  --recurse-submodules                            # update the contents of sub-modules
  --track(-t)                                     # set "upstream" configuration
]

# Find commits yet to be applied to upstream
export extern "yadm cherry" [
  upstream?: string@"nu-complete yadm mergable sources"  # Upstream branch to search for equivalent commits. Defaults to the upstream branch of HEAD.
  head?: string@"nu-complete yadm mergable sources"      # Working branch; defaults to HEAD.
  limit?: string                                        # Do not report commits up to (and including) limit.
  --verbose(-v)                                         # Show the commit subjects next to the SHA1s.
]

# Apply the change introduced by an existing commit
export extern "yadm cherry-pick" [
  commit?: string@"nu-complete yadm commits all" # The commit ID to be cherry-picked
  --edit(-e)                                    # Edit the commit message prior to committing
  --no-commit(-n)                               # Apply changes without making any commit
  --signoff(-s)                                 # Add Signed-off-by line to the commit message
  --ff                                          # Fast-forward if possible
  --continue                                    # Continue the operation in progress
  --abort                                       # Cancel the operation
  --skip                                        # Skip the current commit and continue with the rest of the sequence
]

# Rebase the current branch
export extern "yadm rebase" [
  branch?: string@"nu-complete yadm rebase"    # name of the branch to rebase onto
  upstream?: string@"nu-complete yadm rebase"  # upstream branch to compare against
  --continue                                  # restart rebasing process after editing/resolving a conflict
  --abort                                     # abort rebase and reset HEAD to original branch
  --quit                                      # abort rebase but do not reset HEAD
  --interactive(-i)                           # rebase interactively with list of commits in editor
  --onto?: string@"nu-complete yadm rebase"    # starting point at which to create the new commits
  --root                                      # start rebase from root commit
]

# Merge from a branch
export extern "yadm merge" [
  # For now, to make it simple, we only complete branches (not commits) and support single-parent case.
  branch?: string@"nu-complete yadm mergable sources"         # The source branch
  --edit(-e)                                                 # Edit the commit message prior to committing
  --no-edit                                                  # Do not edit commit message
  --no-commit(-n)                                            # Apply changes without making any commit
  --signoff                                                  # Add Signed-off-by line to the commit message
  --ff                                                       # Fast-forward if possible
  --continue                                                 # Continue after resolving a conflict
  --abort                                                    # Abort resolving conflict and go back to original state
  --quit                                                     # Forget about the current merge in progress
  --strategy(-s): string@"nu-complete yadm merge strategies"  # Merge strategy
  -X: string@"nu-complete yadm merge strategy options"        # Option for merge strategy
  --verbose(-v)
  --help
]

# List or change branches
export extern "yadm branch" [
  ...branch: string@"nu-complete yadm local branches"             # name of branch (or branches) to operate on
  --abbrev                                                       # use short commit hash prefixes
  --edit-description                                             # open editor to edit branch description
  --merged                                                       # list reachable branches
  --no-merged                                                    # list unreachable branches
  --set-upstream-to: string@"nu-complete yadm available upstream" # set upstream for branch
  --unset-upstream                                               # remote upstream for branch
  --all(-a)                                                      # list both remote and local branches
  --copy(-c)                                                     # copy branch together with config and reflog
  --format                                                       # specify format for listing branches
  --move(-m)                                                     # rename branch
  --points-at                                                    # list branches that point at an object
  --show-current                                                 # print the name of the current branch
  --verbose(-v)                                                  # show commit and upstream for each branch
  --color                                                        # use color in output
  --quiet(-q)                                                    # suppress messages except errors
  --delete(-d)                                                   # delete branch
  -D                                                             # force delete branch
  --list(-l)                                                     # list branches
  --contains: string@"nu-complete yadm commits all"               # show only branches that contain the specified commit
  --no-contains                                                  # show only branches that don't contain specified commit
  --track(-t)                                                    # when creating a branch, set upstream
]

# List all variables set in config file, along with their values.
export extern "yadm gitconfig list" [
]

# Emits the value of the specified key.
export extern "yadm gitconfig get" [
]

# Set value for one or more config options.
export extern "yadm gitconfig set" [
]

# Unset value for one or more config options.
export extern "yadm gitconfig unset" [
]

# Rename the given section to a new name.
export extern "yadm gitconfig rename-section" [
]

# Remove the given section from the configuration file.
export extern "yadm gitconfig remove-section" [
]

# Opens an editor to modify the specified config file
export extern "yadm gitconfig edit" [
]

# List or change tracked repositories
export extern "yadm remote" [
  --verbose(-v)                            # Show URL for remotes
]

# Add a new tracked repository
export extern "yadm remote add" [
]

# Rename a tracked repository
export extern "yadm remote rename" [
  remote: string@"nu-complete yadm remotes"             # remote to rename
  new_name: string                                     # new name for remote
]

# Remove a tracked repository
export extern "yadm remote remove" [
  remote: string@"nu-complete yadm remotes"             # remote to remove
]

# Get the URL for a tracked repository
export extern "yadm remote get-url" [
  remote: string@"nu-complete yadm remotes"             # remote to get URL for
]

# Set the URL for a tracked repository
export extern "yadm remote set-url" [
  remote: string@"nu-complete yadm remotes"             # remote to set URL for
  url: string                                          # new URL for remote
]

# Show changes between commits, working tree etc
export extern "yadm diff" [
  rev1_or_file?: string@"nu-complete yadm files-or-refs"
  rev2?: string@"nu-complete yadm refs"
  --cached                                             # show staged changes
  --name-only                                          # only show names of changed files
  --name-status                                        # show changed files and kind of change
  --no-color                                           # disable color output
]

# Commit changes
export extern "yadm commit" [
  --all(-a)                                           # automatically stage all modified and deleted files
  --amend                                             # amend the previous commit rather than adding a new one
  --message(-m): string                               # specify the commit message rather than opening an editor
  --reuse-message(-C): string                         # reuse the message from a previous commit
  --reedit-message(-c): string                        # reuse and edit message from a commit
  --fixup: string                                     # create a fixup/amend commit
  --squash: string                                    # squash commit for autosquash rebase
  --reset-author                                      # reset author information
  --short                                             # short-format output for dry-run
  --branch                                            # show branch info in short-format
  --porcelain                                         # porcelain-ready format for dry-run
  --long                                              # long-format output for dry-run
  --null(-z)                                          # use NUL instead of LF in output
  --file(-F): string                                  # read commit message from file
  --author: string                                    # override commit author
  --date: string                                      # override author date
  --template(-t): string                              # use commit message template file
  --signoff(-s)                                       # add Signed-off-by trailer
  --no-signoff                                        # do not add Signed-off-by trailer
  --trailer: string                                   # add trailer to commit message
  --no-verify(-n)                                     # bypass pre-commit and commit-msg hooks
  --verify                                            # do not bypass pre-commit and commit-msg hooks
  --allow-empty                                       # allow commit with no changes
  --allow-empty-message                               # allow commit with empty message
  --cleanup: string                                   # cleanup commit message
  --edit(-e)                                          # edit commit message
  --no-edit                                           # do not edit commit message
  --include(-i)                                       # include given paths in commit
  --only(-o)                                          # commit only specified paths
  --pathspec-from-file: string                        # read pathspec from file
  --pathspec-file-nul                                 # use NUL character for pathspec file
  --untracked-files(-u): string                       # show untracked files
  --verbose(-v)                                       # show diff in commit message template
  --quiet(-q)                                         # suppress commit summary
  --dry-run                                           # show paths to be committed without committing
  --status                                            # include git-status output in commit message
  --no-status                                         # do not include git-status output
  --gpg-sign(-S)                                      # GPG-sign commit
  --no-gpg-sign                                       # do not GPG-sign commit
  ...pathspec: string                                 # commit files matching pathspec
]

# List commits
export extern "yadm log" [
  # Ideally we'd allow completion of revisions here, but that would make completion of filenames not work.
  -U                                                  # show diffs
  --follow                                            # show history beyond renames (single file only)
  --grep: string                                      # show log entries matching supplied regular expression
]

# Show or change the reflog
export extern "yadm reflog" [
]

# Stage files
export extern "yadm add" [
  ...file: string@"nu-complete yadm add"               # file to add
  --all(-A)                                           # add all files
  --dry-run(-n)                                       # don't actually add the file(s), just show if they exist and/or will be ignored
  --edit(-e)                                          # open the diff vs. the index in an editor and let the user edit it
  --force(-f)                                         # allow adding otherwise ignored files
  --interactive(-i)                                   # add modified contents in the working tree interactively to the index
  --patch(-p)                                         # interactively choose hunks to stage
  --verbose(-v)                                       # be verbose
]

# Delete file from the working tree and the index
# Delete file from the working tree and the index
export extern "yadm rm" [
  ...files: string@"nu-complete yadm tracked files" # tracked file to remove
  -r                                            # recursive
  --force(-f)                                   # override the up-to-date check
  --dry-run(-n)                                 # don't actually remove any file(s)
  --cached                                      # unstage and remove paths only from the index
]

# Show the working tree status
export extern "yadm status" [
  --verbose(-v)                                       # be verbose
  --short(-s)                                         # show status concisely
  --branch(-b)                                        # show branch information
  --show-stash                                        # show stash information
]

# Stash changes for later
export extern "yadm stash push" [
  --patch(-p)                                         # interactively choose hunks to stash
]

# Unstash previously stashed changes
export extern "yadm stash pop" [
  stash?: string@"nu-complete yadm stash-list"          # stash to pop
  --index(-i)                                          # try to reinstate not only the working tree's changes, but also the index's ones
]

# List stashed changes
export extern "yadm stash list" [
]

# Show a stashed change
export extern "yadm stash show" [
  stash?: string@"nu-complete yadm stash-list"
  -U                                                  # show diff
]

# Drop a stashed change
export extern "yadm stash drop" [
  stash?: string@"nu-complete yadm stash-list"
]

# Create a new git repository
# Initialize an empty repository for tracking dotfiles
export extern "yadm init" [
  --force(-f)                                   # overwrite existing repository
  --work-tree(-w): path                         # specify alternative work-tree (default: $HOME)
  --initial-branch(-b): string                  # initial branch name
]

# List or manipulate tags
export extern "yadm tag" [
  --delete(-d): string@"nu-complete yadm tags"         # delete a tag
]

# Prune all unreachable objects
export extern "yadm prune" [
  --dry-run(-n)                                       # dry run
  --expire: string                                    # expire objects older than
  --progress                                          # show progress
  --verbose(-v)                                       # report all removed objects
]

# Start a binary search to find the commit that introduced a bug
export extern "yadm bisect start" [
  bad?: string                 # a commit that has the bug
  good?: string                # a commit that doesn't have the bug
]

# Mark the current (or specified) revision as bad
export extern "yadm bisect bad" [
]

# Mark the current (or specified) revision as good
export extern "yadm bisect good" [
]

# Skip the current (or specified) revision
export extern "yadm bisect skip" [
]

# End bisection
export extern "yadm bisect reset" [
]

# Show help for a git subcommand
export extern "yadm help" [
  command?: string@"nu-complete yadm subcommands"       # subcommand to show help for
]

# git worktree
export extern "yadm worktree" [
  --help(-h)            # display the help message for this command
  ...args
]

# create a new working tree
export extern "yadm worktree add" [
  path: path            # directory to clone the branch
  branch?: string@"nu-complete yadm available upstream" # Branch to clone
  --help(-h)            # display the help message for this command
  --force(-f)           # checkout <branch> even if already checked out in other worktree
  -b                    # create a new branch
  -B                    # create or reset a branch
  --detach(-d)          # detach HEAD at named commit
  --checkout            # populate the new working tree
  --lock                # keep the new working tree locked
  --reason              # reason for locking
  --quiet(-q)           # suppress progress reporting
  --track               # set up tracking mode (see git-branch(1))
  --guess-remote        # try to match the new branch name with a remote-tracking branch
  ...args
]

# list details of each worktree
export extern "yadm worktree list" [
  --help(-h)            # display the help message for this command
  --porcelain           # machine-readable output
  --verbose(-v)         # show extended annotations and reasons, if available
  --expire              # add 'prunable' annotation to worktrees older than <time>
  -z                    # terminate records with a NUL character
  ...args
]

def "nu-complete worktree list" [] {
  let out = (do { ^yadm worktree list } | complete)
  if $out.exit_code != 0 or ($out.stdout | is-empty) { return [] }
  $out.stdout | lines | parse --regex '(?P<value>\S+)\s+(?P<commit>\w+)\s+(?P<description>\S.*)'
}

# prevent a working tree from being pruned
export extern "yadm worktree lock" [
  worktree: string@"nu-complete worktree list"
  --reason: string      # reason because the tree is locked
  --help(-h)            # display the help message for this command
  --reason              # reason for locking
  ...args
]

# move a working tree to a new location
export extern "yadm worktree move" [
  --help(-h)            # display the help message for this command
  --force(-f)           # force move even if worktree is dirty or locked
  ...args
]

# prune working tree information
export extern "yadm worktree prune" [
  --help(-h)            # display the help message for this command
  --dry-run(-n)         # do not remove, show only
  --verbose(-v)         # report pruned working trees
  --expire              # expire working trees older than <time>
  ...args
]

# remove a working tree
export extern "yadm worktree remove" [
  worktree: string@"nu-complete worktree list"
  --help(-h)            # display the help message for this command
  --force(-f)           # force removal even if worktree is dirty or locked
]

# allow working tree to be pruned, moved or deleted
export extern "yadm worktree unlock" [
  worktree: string@"nu-complete worktree list"
  ...args
]

# clones a repo
# Clone an existing repository for dotfiles
export extern "yadm clone" [
  url: string                                   # URL of repository to clone
  --force(-f)                                   # overwrite existing repository
  --work-tree(-w): path                         # specify alternative work-tree (default: $HOME)
  --branch(-b): string                          # branch to checkout
  --bootstrap                                   # run bootstrap program after cloning
  --no-bootstrap                                # do not run bootstrap program after cloning
]

# Restores files in working tree or index to previous versions
export extern "yadm restore" [
  --help(-h)                                    # Display the help message for this command
  --source(-s)                                  # Restore the working tree files with the content from the given tree
  --patch(-p)                                   # Interactively choose hunks to restore
  --worktree(-W)                                # Restore working tree (default if neither --worktree or --staged is used)
  --staged(-S)                                  # Restore index
  --quiet(-q)                                   # Quiet, suppress feedback messages
  --progress                                    # Force progress reporting
  --no-progress                                 # Suppress progress reporting
  --ours                                        # Restore from index using our version for unmerged files
  --theirs                                      # Restore from index using their version for unmerged files
  --merge(-m)                                   # Restore from index and recreate the conflicted merge in unmerged files
  --conflict: string                            # Like --merge but changes the conflict presentation with =<style>
  --ignore-unmerged                             # Restore from index and ignore unmerged entries (unmerged files are left as is)
  --ignore-skip-worktree-bits                   # Ignore sparse checkout patterns and unconditionally restores any files in <pathspec>
  --recurse-submodules                          # Restore the contents of sub-modules in working tree
  --no-recurse-submodules                       # Do not restore the contents of sub-modules in working tree (default)
  --overlay                                     # Do not remove files that don't exist when restoring from tree with --source
  --no-overlay                                  # Remove files that don't exist when restoring from tree with --source (default)
  --pathspec-from-file: string                  # Read pathspec from file
  --pathspec-file-nul                           # Separate pathspec elements with NUL character when reading from file
  ...pathspecs: string@"nu-complete yadm files"  # Target pathspecs to restore
]

# Print lines matching a pattern
export extern "yadm grep" [
  --help(-h)                            # Display the help message for this command
  --cached                              # Search blobs registered in the index file instead of worktree
  --untracked                           # Include untracked files in search
  --no-index                            # Similar to `grep -r`, but with additional benefits, such as using pathspec patterns to limit paths; Cannot be used together with --cached or --untracked
  --no-exclude-standard                 # Include ignored files in search (only useful with --untracked)
  --exclude-standard                    # No not include ignored files in search (only useful with --no-index)
  --recurse-submodules                  # Recursively search in each submodule that is active and checked out
  --text(-a)                            # Process binary files as if they were text
  --textconv                            # Honor textconv filter settings
  --no-textconv                         # Do not honor textconv filter settings (default)
  --ignore-case(-i)                     # Ignore case differences between patterns and files
  -I                                    # Don’t match the pattern in binary files
  --max-depth: int                      # Max <depth> to descend down directories for each pathspec. A value of -1 means no limit.
  --recursive(-r)                       # Same as --max-depth=-1
  --no-recursive                        # Same as --max-depth=0
  --word-regexp(-w)                     # Match the pattern only at word boundary
  --invert-match(-v)                    # Select non-matching lines
  -H                                    # Suppress filename in output of matched lines
  --full-name                           # Force relative path to filename from top directory
  --extended-regexp(-E)                 # Use POSIX extended regexp for patterns
  --basic-regexp(-G)                    # Use POSIX basic regexp for patterns (default)
  --perl-regexp(-P)                     # Use Perl-compatible regular expressions for patterns
  --line-number(-n)                     # Prefix the line number to matching lines
  --column                              # Prefix the 1-indexed byte-offset of the first match from the start of the matching line
  --files-with-matches(-l)              # Print filenames of files that contains matches
  --name-only                           # Same as --files-with-matches
  --files-without-match(-L)             # Print filenames of files that do not contain matches
  --null(-z)                            # Use \0 as the delimiter for pathnames in the output, and print them verbatim
  --only-matching(-o)                   # Print only the matched (non-empty) parts of a matching line, with each such part on a separate output line
  --count(-c)                           # Instead of showing every matched line, show the number of lines that match
  --no-color                            # Same as --color=never
  --break                               # Print an empty line between matches from different files.
  --heading                             # Show the filename above the matches in that file instead of at the start of each shown line.
  --show-function(-p)                   # Show the preceding line that contains the function name of the match, unless the matching line is a function name itself.
  --context(-C): int                    # Show <num> leading and trailing lines, and place a line containing -- between contiguous groups of matches.
  --after-context(-A): int              # Show <num> trailing lines, and place a line containing -- between contiguous groups of matches.
  --before-context(-B): int             # Show <num> leading lines, and place a line containing -- between contiguous groups of matches.
  --function-context(-W)                # Show the surrounding text from the previous line containing a function name up to the one before the next function name
  --max-count(-m): int                  # Limit the amount of matches per file. When using the -v or --invert-match option, the search stops after the specified number of non-matches.
  --threads: int                        # Number of grep worker threads to use. Use --help for more information on grep threads.
  -f: string                            # Read patterns from <file>, one per line.
  -e: string                            # Next parameter is the pattern. Multiple patterns are combined by --or.
  --and                                 # Search for lines that match multiple patterns.
  --or                                  # Search for lines that match at least one of multiple patterns. --or is implied between patterns without --and or --not.
  --not                                 # Search for lines that does not match pattern.
  --all-match                           # When giving multiple pattern expressions combined with --or, this flag is specified to limit the match to files that have lines to match all of them.
  --quiet(-q)                           # Do not output matched lines; instead, exit with status 0 when there is a match and with non-zero status when there isn’t.
  ...pathspecs: string                  # Target pathspecs to limit the scope of the search.
]

export extern "yadm" [
  command?: string@"nu-complete yadm subcommands" # Subcommands
  --yadm-dir: path                              # Override yadm directory (default: ~/.config/yadm)
  --yadm-data: path                             # Override yadm data directory (default: ~/.local/share/yadm)
  --yadm-repo: path                             # Override yadm repository path
  --yadm-config: path                           # Override yadm config path
  --yadm-encrypt: path                          # Override yadm encrypt patterns file
  --yadm-archive: path                          # Override yadm archive file
  --yadm-bootstrap: path                        # Override yadm bootstrap script
  -Y                                            # Path to an alternate yadm script
  --version(-v)                                 # Prints yadm and Git versions
  --help(-h)                                    # Prints yadm synopsis and commands
]

# Configure a yadm setting
export extern "yadm config" [
  name?: string@"nu-complete yadm config names"  # configuration setting name
  value?: string                                 # configuration setting value
  --edit(-e)                                     # edit configuration in editor
  --list(-l)                                     # list configuration settings
]

# Pass options to git config for the yadm repository
export extern "yadm gitconfig" [
  ...args: string                                # arguments passed to git config
]

# Print list of files managed by yadm
export extern "yadm list" [
  --all(-a)                                      # list all managed files including submodules and unlinked alternates
]

# Create links for alternates
export extern "yadm alt" [
]

# Execute bootstrap program ($HOME/.config/yadm/bootstrap)
export extern "yadm bootstrap" [
]

# Encrypt private files
export extern "yadm encrypt" [
]

# Decrypt private files
export extern "yadm decrypt" [
  --list(-l)                                     # list files that would be extracted without decrypting
]

# Update file permissions as described in yadm permissions
export extern "yadm perms" [
]

# Run sub-shell with GIT variables set for yadm repo
export extern "yadm enter" [
  ...command: string                             # command to run in sub-shell
]

# Run git-crypt commands for the yadm repo
export extern "yadm git-crypt" [
  ...args: string                                # git-crypt arguments
]

# Run transcrypt commands for the yadm repo
export extern "yadm transcrypt" [
  ...args: string                                # transcrypt arguments
]

# Upgrade yadm to latest version
export extern "yadm upgrade" [
  --force(-f)                                    # force upgrade
]

# Print yadm version
export extern "yadm version" [
]

# Report internal yadm data for completion and debugging
export extern "yadm introspect" [
  category: string@"nu-complete yadm introspect categories" # category: commands, configs, repo, switches
]
