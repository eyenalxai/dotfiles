# zoxide-completions.nu
# Custom completions for zoxide's z and zi commands in Nushell
# nu-version: 0.115.1

use ./completion-helpers.nu *

# Directories that the word being completed names: `b` -> `bin` in the current
# directory, `~/Pro` -> `~/Projects`, `Projects/ot` -> the children of
# `Projects` whose name starts with `ot`. `z <directory>` jumps straight to such
# a path without consulting the database, so these are listed before database
# matches.
def "nu-complete zoxide dirs" [token: string] {
  if ($token | is-empty) { return [] }

  # `Projects/` lists the children of `Projects`; `Projects/ot` narrows them.
  let parts = (
    if ($token | str ends-with '/') {
      {
        base: (if $token == '/' { '/' } else { $token | str trim --right --char '/' })
        prefix: ''
      }
    } else if $token == '~' {
      { base: '~', prefix: '' }
    } else {
      let parsed = ($token | path parse)
      {
        base: (if ($parsed.parent | is-empty) { '.' } else { $parsed.parent })
        prefix: $parsed.stem
      }
    }
  )

  # Expand the base first: `ls` does not expand a `~` that comes from a
  # variable, and absolute names make the candidates independent of the cwd.
  let base = ($parts.base | path expand)
  let entries = (try { ls --all $base } catch { [] })

  $entries
  | where type == 'dir'
  | where {|entry| ($entry.name | path basename) | str starts-with --ignore-case $parts.prefix }
  | get name
  | each {|name| nu-complete escape ($name | path expand) }
  | sort
}

# Arguments of z and zi: directories the current word names plus entries from
# the zoxide database in frecency order. The engine's own narrowing is disabled
# because both sources already decide what matches, and zoxide's order must be
# preserved rather than re-sorted.
def "nu-complete zoxide path" [context: string] {
  let line = (nu-complete words $context)
  let words = ($line.words | skip 1)
  # While the cursor is still in the command name there is no word to complete.
  let token = (if ($words | is-empty) { '' } else { $line.token })

  let from_db = (
    try {
      ^zoxide query --list --exclude $env.PWD -- ...$words
      | lines
      | where {|dir| $dir | is-not-empty }
      | first 100
      | each {|dir| nu-complete escape $dir }
    } catch {
      []
    }
  )

  # `z` treats its argument as a path only when it is the sole argument.
  let from_disk = (
    if ($words | length) <= 1 {
      nu-complete zoxide dirs $token
    } else {
      []
    }
  )

  let completions = (
    $from_disk
    | append ($from_db | where {|dir| $dir not-in $from_disk })
    | first 100
  )

  {
    completions: $completions
    options: {
      filter: false
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
