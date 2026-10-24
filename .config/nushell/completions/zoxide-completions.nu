# zoxide-completions.nu
# Custom completions for zoxide's z and zi commands in Nushell
# nu-version: 0.116.1

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
  | each {|name| $name | path expand }
  | sort
}

# Menu text for each candidate: the shortest run of trailing path parts that no
# other candidate shares. `phaephe` stands alone, and two directories both named
# `oof` become `woof/oof` and `boof/oof`. A path whose tails all collide shows
# its full path as the last resort.
def "nu-complete zoxide labels" [paths: list<string>] {
  if ($paths | is-empty) { return [] }

  let parts = ($paths | each {|path|
    $path | path split | where {|part| $part != '/' and ($part | is-not-empty) }
  })
  let widest = ($parts | each {|path| $path | length } | math max)
  let max_depth = (if $widest < 1 { 1 } else { $widest })

  # tails: for every depth, the trailing parts of every path at that depth.
  # `each` drops null results, so a path with no tail at this depth yields an
  # empty string, which no real path tail can be.
  let tails = (1..$max_depth | each {|depth|
    $parts | each {|path|
      if ($path | is-empty) or ($depth > ($path | length)) {
        ''
      } else {
        $path | last $depth | path join
      }
    }
  })

  $paths | enumerate | each {|row|
    mut depth = 1
    mut label = ''
    while $depth <= $max_depth and ($label | is-empty) {
      let candidate = ($tails | get ($depth - 1) | get $row.index)
      let shared = (
        $tails
        | get ($depth - 1)
        | enumerate
        | where {|other| $other.index != $row.index and $other.item == $candidate}
        | is-not-empty
      )
      if ($candidate | is-not-empty) and not $shared {
        $label = $candidate
      }
      $depth += 1
    }
    if ($label | is-empty) { $label = ($paths | get $row.index) }
    $label
  }
}

# Arguments of z and zi: directories the current word names plus entries from
# the zoxide database in frecency order. The engine's own narrowing is disabled
# because both sources already decide what matches, and zoxide's order must be
# preserved rather than re-sorted. The menu shows only the distinguishing tail
# of each path, but the full path is inserted so `z` can jump straight to it.
def "nu-complete zoxide path" [place: record] {
  # `place.command` holds the words of the command being completed, even after
  # a pipe or through an alias. Join them back into a line for
  # `nu-complete words`, which drops quoting and finds the word at the cursor.
  let line = (nu-complete words ($place.command | str join ' '))
  let words = ($line.words | skip 1)
  # While the cursor is still in the command name there is no word to complete.
  let token = (if ($words | is-empty) { '' } else { $line.token })

  let from_db = (
    try {
      ^zoxide query --list --exclude $env.PWD -- ...$words
      | lines
      | where {|dir| $dir | is-not-empty }
      | first 100
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

  let candidates = (
    $from_disk
    | append ($from_db | where {|dir| $dir not-in $from_disk })
    | first 100
  )
  let labels = (nu-complete zoxide labels $candidates)

  {
    completions: ($candidates | enumerate | each {|row|
      {
        value: (nu-complete escape $row.item)
        display_override: ($labels | get $row.index)
      }
    })
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
