# gh-completions.nu
# Custom completions for the GitHub CLI (gh) in Nushell
# nu-version: 0.115.1

use ./completion-helpers.nu *

# Complete gh arguments with the completion protocol gh ships for shells:
# `gh __complete <words...> <word>` prints one `value<TAB>description` line per
# candidate followed by a `:<directive>` line, interpreting the words exactly as
# gh itself would. Delegating the whole command line keeps subcommands, flags
# and dynamic values (repositories, branches, pull requests, ...) in sync with
# the installed gh instead of vendoring a snapshot of its command tree.
def "nu-complete gh candidates" [args: list<string>] {
  # `__complete` prints the directive it chose to stderr; only stdout matters.
  # The timeout only guards dynamic completions, which query the GitHub API.
  let res = (do { ^timeout 5 gh __complete ...$args } | complete)
  if ($res.stdout | is-empty) { return null }

  let lines = ($res.stdout | lines | where {|line| $line | is-not-empty })
  let last = ($lines | last)
  let has_directive = ($last | str starts-with ':')
  let directive = (if $has_directive { $last | str substring 1.. | into int } else { 0 })
  let raw = (if $has_directive { $lines | take (($lines | length) - 1) } else { $lines })

  # ShellCompDirectiveError: gh could not complete; do not show anything.
  if (($directive | bits and 1) != 0) { return [] }

  let completions = (
    $raw
    | where {|line| not ($line | str starts-with '_activeHelp_') }
    | each {|line|
        let parts = ($line | split row "\t")
        {
          value: (nu-complete escape $parts.0)
          description: ($parts.1? | default '')
        }
      }
  )

  # ShellCompDirectiveDefault (no bit set) means gh leaves the slot to the
  # shell's normal behavior — file completion — unless it produced candidates.
  if ($completions | is-empty) and (($directive | bits and 4) == 0) {
    return null
  }

  $completions
}

# Whole-command completer attached to the gh extern below with `@complete`:
# a positional completer is never consulted for `--flag` words, so completing
# flags requires this command-wide form. It receives every word of the
# invocation, including the command itself.
def "nu-complete gh" [spans: list<string>] {
  # `gh <TAB>` has no words after the command yet; __complete still wants the
  # word being completed, which is then empty.
  let args = ($spans | skip 1)
  let args = (if ($args | is-empty) { [''] } else { $args })
  try { nu-complete gh candidates $args } catch { null }
}

# GitHub CLI
#
# Arguments — including flags — are completed by gh itself through the
# `__complete` protocol it ships for shells, so subcommands and dynamic values
# stay in sync with the installed gh. Arguments are glob-expanded like a bare
# external command's, so unquoted globs (e.g. `dist/*.zip`) still work.
@complete "nu-complete gh"
export extern "gh" [
  ...rest: glob  # Arguments passed to gh
]
