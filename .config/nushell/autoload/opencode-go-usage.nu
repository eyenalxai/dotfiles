# OpenCode Go usage for every saved account.
#
# Reads all OpenCode Go credentials from the OpenCode credential store and asks
# the Go usage endpoint for each account's rolling / weekly / monthly usage,
# then renders the same numbers the OpenCode console shows -- for all accounts
# at once.
#
# Requires the OpenCode v2 CLI (`opencode2 auth export`); use `--binary` to
# point at another binary.
#
# Usage:
#   opencode-go-usage              # colored bars for every saved account
#   opencode-go-usage --json       # raw usage data for scripting
#   opencode-go-usage -w 40 --no-color

const GO_USAGE_URL = "https://opencode.ai/zen/go/v1/usage"
const GO_INTEGRATION = "opencode-go"

def opencode-go-binary [override: string] {
  if ($override | is-not-empty) { return $override }
  let from_env = ($env.OPENCODE_BIN? | default "")
  if ($from_env | is-not-empty) { return $from_env }
  for candidate in [opencode2 opencode] {
    if (which $candidate | is-not-empty) { return $candidate }
  }
  error make { msg: "opencode CLI not found; install OpenCode v2 or pass --binary" }
}

def opencode-go-reset [at: datetime] {
  let delta = ($at - (date now))
  if ($delta / 1sec | math floor) <= 0 { return "now" }
  let days = ($delta / 1day | math floor)
  let hours = (($delta mod 1day) / 1hr | math floor)
  let minutes = ((($delta mod 1day) mod 1hr) / 1min | math floor)
  if $days >= 1 { return $"($days)d ($hours)h" }
  if $hours >= 1 { return $"($hours)h ($minutes)m" }
  if $minutes >= 1 { return $"($minutes)m" }
  "<1m"
}

def opencode-go-color [percent: int, status: string] {
  if $status == "rate-limited" { return "red" }
  if $percent >= 80 { return "yellow" }
  "green"
}

def opencode-go-filled [percent: int, width: int] {
  let clamped = (if $percent > 100 { 100 } else if $percent < 0 { 0 } else { $percent })
  let count = ($clamped * $width / 100 | math round | into int)
  [$count 0] | math max
}

def opencode-go-bar [percent: int, width: int, color: string] {
  let bar_width = ([$width 0] | math max)
  let filled = (opencode-go-filled $percent $bar_width)
  let fill = ("" | fill -w $filled -c "█")
  let track = ("" | fill -w ($bar_width - $filled) -c "░")
  if ($color | is-empty) { return ($fill + $track) }
  $"($color)($fill)(ansi reset)(ansi dark_gray)($track)(ansi reset)"
}

def opencode-go-account [row: record, width: int, tint: bool] {
  let title = (if $tint { (ansi default_bold) + $row.label + (ansi reset) } else { $row.label })
  let active = (if $row.active {
    if $tint { $"  (ansi green)● active(ansi reset)" } else { "  ● active" }
  } else { "" })
  print $"($title)($active)"

  if not $row.ok {
    let failed = (if $tint { (ansi red) + "unavailable" + (ansi reset) } else { "unavailable" })
    print $"  ($failed): ($row.error)"
    return
  }

  let windows = [
    { id: rolling, label: "Rolling usage" }
    { id: weekly, label: "Weekly usage" }
    { id: monthly, label: "Monthly usage" }
  ]
  for window in $windows {
    let usage = ($row.usage | get $window.id)
    let code = (opencode-go-color $usage.percent $usage.status)
    let color = (if $tint { (ansi $code) } else { "" })
    let bar = (opencode-go-bar $usage.percent $width $color)
    let label = ($window.label | fill -a l -w 13 -c " ")
    let percent = ($usage.percent | into string | fill -a r -w 3 -c " ")
    let percent_text = (if $tint { $"($color)($percent)% used(ansi reset)" } else { $"($percent)% used" })
    let resets = (opencode-go-reset ($usage.resetsAt | into datetime))
    let dim = (if $tint { (ansi dark_gray) } else { "" })
    let reset_text = ($dim + "Resets in" + (if $tint { (ansi reset) } else { "" }))
    let limited = (if $usage.status == "rate-limited" {
      if $tint { $"  (ansi red)· limit reached(ansi reset)" } else { "  · limit reached" }
    } else { "" })
    print $"  ($label)  ($bar)  ($percent_text)   ($reset_text) ($resets)($limited)"
  }
}

# Show rolling / weekly / monthly OpenCode Go usage for all saved accounts.
def opencode-go-usage [
  --width (-w): int = 24        # Width of the usage bars
  --binary (-b): string = ""    # opencode CLI binary (default: $OPENCODE_BIN, opencode2, opencode)
  --endpoint (-e): string = ""  # Usage endpoint override
  --json (-j)                   # Print raw usage data as JSON
  --no-color                    # Disable colored output
] {
  let setting = (($env.config? | default {} | get use_ansi_coloring? | default "auto") | into string | str lowercase)
  let tint = (not $no_color) and (($env.NO_COLOR? | default "") | is-empty) and (if $setting == "false" {
    false
  } else if $setting == "true" {
    true
  } else {
    (is-terminal --stdout) and (not (is-redirected))
  })
  let bin = (opencode-go-binary $binary)
  let endpoint = (if ($endpoint | is-not-empty) { $endpoint } else { $GO_USAGE_URL })

  let accounts = (try {
    ^$bin auth export | from json | where {|row| $row.integrationID == $GO_INTEGRATION and (($row.value.type? | default "") == "key") } | sort-by label
  } catch {|err|
    error make { msg: ($"could not read OpenCode credentials with `($bin) auth export`: ($err.msg? | default 'unknown error')" + " (saved OpenCode Go accounts require the OpenCode v2 CLI, e.g. `opencode2`; or pass --binary)") }
  })

  if ($accounts | is-empty) {
    print "No OpenCode Go accounts found."
    return
  }

  let rows = ($accounts | enumerate | par-each {|entry|
    let account = $entry.item
    let result = (try {
      let body = (http get --max-time 20sec --headers { Authorization: $"Bearer ($account.value.key)" } $endpoint)
      if ($body.usage? | is-empty) {
        { ok: false, error: "unexpected response from the usage endpoint", usage: {} }
      } else {
        { ok: true, error: "", usage: $body.usage }
      }
    } catch {|err|
      { ok: false, error: ($err.msg? | default "request failed"), usage: {} }
    })
    {
      index: $entry.index
      label: $account.label
      active: ($account.active | default false)
      ok: $result.ok
      error: $result.error
      usage: $result.usage
    }
  } | sort-by index | reject index)

  if $json {
    return ($rows | to json --indent 2)
  }

  $rows | enumerate | each {|item|
    if $item.index > 0 { print "" }
    opencode-go-account $item.item $width $tint
  } | ignore
}
