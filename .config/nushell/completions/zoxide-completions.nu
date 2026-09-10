# zoxide-completions.nu
# Custom completions for zoxide's z and zi commands in Nushell
# nu-version: 0.115.1

# Directories from the zoxide database matching the words typed after z/zi.
# Returns the completion envelope so the engine matches substrings (a typed
# keyword like `nushell` can match `/home/.../nushell`) and keeps zoxide's
# frecency order instead of re-sorting alphabetically.
def "nu-complete zoxide path" [context: string] {
  # context is the command text up to the cursor, e.g. `z nushell`
  let keywords = (
    $context
    | split words
    | skip 1
    | each {|word| $word | str replace -a '"' '' | str replace -a "'" '' }
    | where {|word| $word | is-not-empty }
  )

  let dirs = (
    try {
      ^zoxide query --list --exclude $env.PWD -- ...$keywords
      | lines
      | where {|dir| $dir | is-not-empty }
      | first 100
    } catch {
      []
    }
  )

  {
    completions: $dirs
    options: {
      completion_algorithm: "substring"
      case_sensitive: false
      sort: false
    }
  }
}

# zoxide defines z and zi as aliases, which cannot carry completions. These
# wrappers call the functions `zoxide init nushell` generated (see zoxide.nu)
# and add a completer for their arguments.
def --env --wrapped z [...rest: directory@"nu-complete zoxide path"] {
  __zoxide_z ...$rest
}

def --env --wrapped zi [...rest: string@"nu-complete zoxide path"] {
  __zoxide_zi ...$rest
}
