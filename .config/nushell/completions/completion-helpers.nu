# completion-helpers.nu
# Shared helpers for Nushell custom completions.
# nu-version: 0.115.1
#
# This file is `use`d by the individual completion files in this directory and
# intentionally knows nothing about any particular CLI.

# ==============================================================================
# Command line tokenizing
# ==============================================================================

# Split a command line into words the way the parser does: whitespace separates
# words and single or double quotes group their contents into one word (the
# quote characters themselves are dropped). Returns the words plus the word the
# cursor is inside, which is empty right after a separator.
export def "nu-complete words" [context: string] {
  mut words = []
  mut word = ''
  mut quote = ''
  mut separated = true
  for char in ($context | split chars) {
    if ($quote | is-not-empty) {
      $separated = false
      if $char == $quote {
        $quote = ''
      } else {
        $word += $char
      }
    } else if $char == '"' or $char == "'" {
      $separated = false
      $quote = $char
    } else if ($char =~ '\s') {
      if ($word | is-not-empty) {
        $words ++= [$word]
        $word = ''
      }
      $separated = true
    } else {
      $separated = false
      $word += $char
    }
  }
  if ($word | is-not-empty) { $words ++= [$word] }
  {
    words: $words
    token: (if $separated { '' } else { $word })
  }
}

# Quote a path that contains characters which would break out of a bare word,
# mirroring how nu-cli escapes its own file completions.
export def "nu-complete escape" [path: string] {
  if ($path =~ '[*?\[]') or ($path | str contains '`') {
    # glob metacharacters and backticks: single quotes keep them literal
    if ($path | str contains "'") {
      $path | to nuon
    } else {
      $"'($path)'"
    }
  } else if ($path =~ "[\\s'\"#(){}|;]") or ($path | str contains ']') {
    $"`($path)`"
  } else {
    $path
  }
}

# ==============================================================================
# Cached JSON produced by external commands
# ==============================================================================

# Root of the completion cache for one CLI: $XDG_CACHE_HOME/nu-completions/<namespace>
export def "nu-complete cache dir" [namespace: string] {
  let base = ($env.XDG_CACHE_HOME? | default ($env.HOME | path join ".cache"))
  $base | path join "nu-completions" $namespace
}

# Restrict permissions on cached data (best effort)
export def "nu-complete cache chmod" [path: string, mode: string] {
  try { ^chmod $mode $path | ignore } catch {}
}

# Fetch JSON with an external command and store it in the completion cache.
# Runs in a background job: callers pass a generous timeout.
export def "nu-complete cache refresh" [
  namespace: string
  name: string
  command: list<string> # Full argv, including the executable
  timeout: duration
  extra_env?: record
] {
  let dir = (nu-complete cache dir $namespace)
  let file = ($dir | path join $"($name).json")
  try {
    let seconds = (($timeout / 1sec) | math floor | into int)
    let res = (
      if ($extra_env | is-empty) {
        do { ^timeout $seconds ...$command } | complete
      } else {
        with-env $extra_env { do { ^timeout $seconds ...$command } | complete }
      }
    )
    if $res.exit_code == 0 and ($res.stdout | is-not-empty) {
      if not ($dir | path exists) { mkdir $dir }
      nu-complete cache chmod $dir 700
      let tmp = ($dir | path join $"($name).tmp.json")
      $res.stdout | from json | to json | save -f $tmp
      mv -f $tmp $file
      nu-complete cache chmod $file 600
    }
  }
}

# Return JSON produced by an external command, caching it on disk. Fresh cache
# entries are served directly; stale ones are served while a background job
# refreshes them. The first run waits up to `timeout` so completions are useful
# immediately.
export def "nu-complete cached json" [
  namespace: string
  name: string
  command: list<string> # Full argv, including the executable
  ttl: duration
  extra_env?: record
  timeout: duration = 6sec
] {
  let dir = (nu-complete cache dir $namespace)
  let file = ($dir | path join $"($name).json")
  let lock = ($dir | path join $"($name).lock")
  if not ($dir | path exists) { mkdir $dir }
  nu-complete cache chmod $dir 700

  let exists = ($file | path exists)
  let fresh = if $exists {
    try { ((date now) - (ls -D $file | get 0.modified)) < $ttl } catch { false }
  } else {
    false
  }
  if $fresh {
    return (try { open $file } catch { [] })
  }

  if not $exists {
    # First run: wait briefly so completions are useful immediately
    let seconds = (($timeout / 1sec) | math floor | into int)
    let res = (
      if ($extra_env | is-empty) {
        do { ^timeout $seconds ...$command } | complete
      } else {
        with-env $extra_env { do { ^timeout $seconds ...$command } | complete }
      }
    )
    if $res.exit_code == 0 and ($res.stdout | is-not-empty) {
      try {
        let data = ($res.stdout | from json)
        let tmp = ($dir | path join $"($name).tmp.json")
        $data | to json | save -f $tmp
        mv -f $tmp $file
        nu-complete cache chmod $file 600
        return $data
      } catch {}
    }
  }

  # Serve stale data and refresh the cache in the background
  let lock_fresh = if ($lock | path exists) {
    try { ((date now) - (ls -D $lock | get 0.modified)) < 1min } catch { false }
  } else {
    false
  }
  if not $lock_fresh {
    touch $lock
    job spawn {|| nu-complete cache refresh $namespace $name $command 30sec $extra_env } | ignore
  }

  try { open $file } catch { [] }
}
