# bat-completions.nu
# Custom completions for bat, and for the `cat` wrapper that decorates it
# (`cat` runs `bat --plain --paging=never`), in Nushell.
# nu-version: 0.115.1

use ./completion-helpers.nu *

# ==============================================================================
# Value completions
# ==============================================================================

# Flags which only accept a fixed set of keywords.
def "nu-complete bat notations" [] { [unicode caret] }
def "nu-complete bat binary-behaviors" [] { [no-printing as-text] }
def "nu-complete bat wrap-modes" [] { [auto never character] }
def "nu-complete bat color-when" [] { [auto never always] }
def "nu-complete bat always-never" [] { [always never] }
def "nu-complete bat strip-ansi-when" [] { [auto always never] }
def "nu-complete bat shells" [] { [bash fish zsh ps1] }

# Theme names, asked of bat itself so they stay in sync with the installed
# version and with any custom themes.
def "nu-complete bat themes" [] {
  try { ^bat --list-themes | lines | where {|line| $line | is-not-empty } } catch { [] }
}

# Language names. `--list-languages` prints `Name:ext1,ext2,...`; the name is the
# value and the extensions are shown as its description.
def "nu-complete bat languages" [] {
  try {
    ^bat --list-languages
    | lines
    | where {|line| $line | is-not-empty }
    | parse --regex '^(?P<name>.+?):(?P<extensions>.*)$'
    | each {|language| {value: $language.name, description: $language.extensions} }
  } catch { [] }
}

# `--style` takes a comma-separated list of components, so after the first
# component complete the next one while keeping the prefix already typed.
def "nu-complete bat styles" [context: string] {
  let components = [
    default full auto plain changes header header-filename header-filesize
    grid rule numbers snip
  ]
  let token = ((nu-complete words $context) | get token)
  if ($token | str contains ',') {
    let prefix = ($token | str substring 0..($token | str index-of ','))
    $components | each {|component| $"($prefix)($component)" }
  } else {
    $components
  }
}

# ==============================================================================
# Flag metadata
# ==============================================================================

# The flags of the `bat` extern, read back from its signature so the `cat`
# wrapper below cannot drift from it. One entry per spelling (`--long` and
# `-s`), matching how Nushell completes flags for the extern itself.
def "nu-complete bat flags" [] {
  let rows = (
    try {
      scope commands | where name == 'bat' | get 0.signatures | values | first
    } catch { [] }
  )
  $rows
  | where {|row| $row.parameter_type in ['switch' 'named'] }
  | each {|row|
      let description = ($row.description | default '')
      let long = (
        if ($row.parameter_name | is-empty) { [] } else {
          [{ value: $"--($row.parameter_name)", description: $description }]
        }
      )
      let short = (
        if ($row.short_flag | is-empty) { [] } else {
          [{ value: $"-($row.short_flag)", description: $description }]
        }
      )
      $long | append $short
    }
  | flatten
}

# Keep only the candidates whose value starts with the typed token. Accepts
# plain strings and `{value, description}` records alike.
def "nu-complete bat filter" [token: string] {
  if ($token | is-empty) {
    $in
  } else {
    $in | where {|candidate|
      let value = (
        if (($candidate | describe) | str starts-with 'record') {
          $candidate.value
        } else {
          $candidate
        }
      )
      $value | str starts-with --ignore-case $token
    }
  }
}

# Values accepted by a single value-taking flag, or `null` when the flag takes
# a path/string that Nushell should complete on its own.
def "nu-complete cat flag-values" [flag: string, token: string = ''] {
  match $flag {
    '--theme' | '--theme-light' | '--theme-dark' => (nu-complete bat themes)
    '--language' | '-l' => (nu-complete bat languages)
    '--style' => (nu-complete bat styles $token)
    '--color' | '--decorations' | '--paging' => (nu-complete bat color-when)
    '--strip-ansi' => (nu-complete bat strip-ansi-when)
    '--italic-text' => (nu-complete bat always-never)
    '--wrap' => (nu-complete bat wrap-modes)
    '--binary' => (nu-complete bat binary-behaviors)
    '--nonprintable-notation' => (nu-complete bat notations)
    '--completion' => (nu-complete bat shells)
    _ => null
  }
}

# Whole-command completer for the `cat` wrapper, attached with `@complete`.
# Wrapped commands collect their flags into `...args` instead of declaring them,
# so flag names are read from the `bat` extern and completed here.
def "nu-complete cat" [spans: list<string>] {
  let args = ($spans | skip 1)
  # The parser appends an empty argument when the cursor sits after a space.
  let last = ($args | last | default '')
  let separated = ($last | is-empty)
  let words = ($args | where {|word| $word | is-not-empty })
  let token = (if $separated { '' } else { $last })
  let previous = (
    if $separated { $words | last | default '' } else if ($words | length) >= 2 {
      $words | get (($words | length) - 2)
    } else {
      ''
    }
  )

  # `--flag=value`: complete the value while keeping the `--flag=` prefix.
  if ($token | str starts-with '-') and ($token | str contains '=') {
    let separator = ($token | str index-of '=')
    let flag = ($token | str substring 0..<$separator)
    let value = ($token | str substring ($separator + 1)..)
    let candidates = (
      nu-complete cat flag-values $flag $value | nu-complete bat filter $value
    )
    if ($candidates | is-empty) { return null }
    return (
      $candidates | each {|candidate|
        let candidate = (
          if (($candidate | describe) | str starts-with 'record') {
            $candidate.value
          } else {
            $candidate
          }
        )
        $"($flag)=($candidate)"
      }
    )
  }

  # A flag name (`-`, `--th`, ...): suggest the matching spellings.
  if ($token | str starts-with '-') {
    return (nu-complete bat flags | nu-complete bat filter $token)
  }

  # A value for the preceding value-taking flag (`--theme dr`, `--theme <TAB>`).
  let values = (nu-complete cat flag-values $previous $token)
  if ($values | is-empty) {
    # Nothing flag-specific: let Nushell complete file paths.
    return null
  }
  $values | nu-complete bat filter $token
}

# bat - a cat(1) clone with syntax highlighting and Git integration
export extern "bat" [
    ...files: path                                          # Files to print; use '-' or no argument to read stdin

    --show-all(-A)                                          # Show non-printable and non-printing characters
    --nonprintable-notation: string@"nu-complete bat notations"  # Notation for non-printable characters
    --binary: string@"nu-complete bat binary-behaviors"     # How to treat binary content
    --plain(-p)                                             # Only show plain style (repeat for --style=plain --paging=never)
    --language(-l): string@"nu-complete bat languages"      # Set the language for syntax highlighting
    --highlight-line(-H): string                            # Highlight the given line ranges
    --file-name: string                                     # Name to display for a file and use for syntax detection
    --diff(-d)                                              # Only show lines changed relative to the Git index
    --diff-context: int                                     # Lines of context around changes with --diff
    --tabs: int                                             # Tab width (0 passes tabs through)
    --wrap: string@"nu-complete bat wrap-modes"             # Text wrapping mode
    --chop-long-lines(-S)                                   # Truncate lines longer than the screen width
    --terminal-width: string                                # Explicit terminal width (may be prefixed with +/-)
    --number(-n)                                            # Only show line numbers
    --color: string@"nu-complete bat color-when"            # When to use colored output
    --italic-text: string@"nu-complete bat always-never"    # When to use ANSI italic sequences
    --decorations: string@"nu-complete bat color-when"      # When to show decorations
    --force-colorization(-f)                                # Alias for --decorations=always --color=always
    --paging: string@"nu-complete bat color-when"           # When to use the pager
    --pager: string                                         # Pager command to use
    --map-syntax(-m): string                                # Map a glob pattern to a syntax name
    --ignored-suffix: string                                # Ignore a file extension when detecting syntax
    --theme: string@"nu-complete bat themes"                # Theme for syntax highlighting
    --theme-light: string@"nu-complete bat themes"          # Theme used on light backgrounds
    --theme-dark: string@"nu-complete bat themes"           # Theme used on dark backgrounds
    --list-themes                                           # List supported themes
    --squeeze-blank(-s)                                     # Squeeze consecutive empty lines
    --squeeze-limit: int                                    # Maximum number of consecutive empty lines
    --strip-ansi: string@"nu-complete bat strip-ansi-when"  # When to strip ANSI sequences from the input
    --style: string@"nu-complete bat styles"                # Components to show in addition to file contents
    --line-range(-r): string                                # Only print the given line ranges
    --list-languages(-L)                                    # List supported languages
    --unbuffered(-u)                                        # Accepted for POSIX compatibility; ignored
    --completion: string@"nu-complete bat shells"           # Print shell completion for a shell
    --diagnostic                                            # Show diagnostic information for bug reports
    --acknowledgements                                      # Show acknowledgements
    --set-terminal-title                                    # Set the terminal title to filenames when using a pager
    --help(-h)                                              # Print help
    --version(-V)                                           # Print version
]

# `cat` is a decorated `bat`. Aliases cannot carry completions, so it is defined
# here as a wrapped command sharing bat's completer.
@complete "nu-complete cat"
def --wrapped cat [...args: string] {
    ^bat --plain --paging=never ...$args
}
