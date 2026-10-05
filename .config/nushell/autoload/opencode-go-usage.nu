# OpenCode Go usage for every saved account.
#
# Reads all OpenCode Go credentials from the OpenCode credential store and asks
# the Go usage endpoint for each account's rolling / weekly / monthly usage,
# then renders the same numbers the OpenCode console shows -- for all accounts
# at once. Each window gets two bars: one for usage, one for how far the
# window has elapsed, so you can see whether usage is keeping pace with time.
#
# `--history` adds API-equivalent usage history from the local OpenCode
# database: tokens used and what the same usage would have cost at API prices,
# for today, the last 24 hours, 3 days, week, month, and all time.
#
# Requires the OpenCode v2 CLI (`opencode2 auth export`); use `--binary` to
# point at another binary.
#
# Usage:
#   opencode-go-usage              # colored bars for every saved account
#   opencode-go-usage --history    # also show API-equivalent usage history
#   opencode-go-usage --json       # raw usage data for scripting
#   opencode-go-usage --json --history  # { accounts, history } for the bar widget
#   opencode-go-usage -w 40 --no-color

const GO_USAGE_URL = "https://opencode.ai/zen/go/v1/usage"
const GO_INTEGRATION = "opencode-go"

# API-equivalent usage history for rolling windows, computed from the local
# OpenCode database. Every completed assistant step stores its own cost (the
# price the same tokens would have cost at API rates) plus a token breakdown,
# so summing per step is both accurate and windowable. The v1 `message` table
# is only consulted for rows that never made it into `session_message`.
const GO_HISTORY_SQL = r#'
WITH bounds AS (
  SELECT
    CAST(strftime('%s','now','localtime','start of day','utc') AS INTEGER) * 1000 AS today_ms,
    (CAST(strftime('%s','now') AS INTEGER) - 86400) * 1000 AS h24_ms,
    (CAST(strftime('%s','now') AS INTEGER) - 259200) * 1000 AS d3_ms,
    (CAST(strftime('%s','now') AS INTEGER) - 604800) * 1000 AS week_ms,
    (CAST(strftime('%s','now') AS INTEGER) - 2592000) * 1000 AS month_ms
),
m AS (
  SELECT time_created,
    json_extract(data,'$.cost') AS cost,
    json_extract(data,'$.tokens.input') AS input,
    json_extract(data,'$.tokens.output') AS output,
    json_extract(data,'$.tokens.reasoning') AS reasoning,
    json_extract(data,'$.tokens.cache.read') AS cache_read,
    json_extract(data,'$.tokens.cache.write') AS cache_write
  FROM session_message
  WHERE type = 'assistant' AND json_extract(data,'$.cost') IS NOT NULL
  UNION ALL
  SELECT time_created,
    json_extract(data,'$.cost'),
    json_extract(data,'$.tokens.input'),
    json_extract(data,'$.tokens.output'),
    json_extract(data,'$.tokens.reasoning'),
    json_extract(data,'$.tokens.cache.read'),
    json_extract(data,'$.tokens.cache.write')
  FROM message
  WHERE json_extract(data,'$.role') = 'assistant'
    AND json_extract(data,'$.cost') IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM session_message s WHERE s.id = message.id)
)
SELECT 'today' AS period, COUNT(*) AS steps, ROUND(COALESCE(SUM(cost),0),6) AS cost,
  COALESCE(SUM(input),0) AS input, COALESCE(SUM(output),0) AS output, COALESCE(SUM(reasoning),0) AS reasoning,
  COALESCE(SUM(cache_read),0) AS cache_read, COALESCE(SUM(cache_write),0) AS cache_write
FROM m WHERE time_created >= (SELECT today_ms FROM bounds)
UNION ALL
SELECT 'h24', COUNT(*), ROUND(COALESCE(SUM(cost),0),6),
  COALESCE(SUM(input),0), COALESCE(SUM(output),0), COALESCE(SUM(reasoning),0),
  COALESCE(SUM(cache_read),0), COALESCE(SUM(cache_write),0)
FROM m WHERE time_created >= (SELECT h24_ms FROM bounds)
UNION ALL
SELECT 'd3', COUNT(*), ROUND(COALESCE(SUM(cost),0),6),
  COALESCE(SUM(input),0), COALESCE(SUM(output),0), COALESCE(SUM(reasoning),0),
  COALESCE(SUM(cache_read),0), COALESCE(SUM(cache_write),0)
FROM m WHERE time_created >= (SELECT d3_ms FROM bounds)
UNION ALL
SELECT 'week', COUNT(*), ROUND(COALESCE(SUM(cost),0),6),
  COALESCE(SUM(input),0), COALESCE(SUM(output),0), COALESCE(SUM(reasoning),0),
  COALESCE(SUM(cache_read),0), COALESCE(SUM(cache_write),0)
FROM m WHERE time_created >= (SELECT week_ms FROM bounds)
UNION ALL
SELECT 'month', COUNT(*), ROUND(COALESCE(SUM(cost),0),6),
  COALESCE(SUM(input),0), COALESCE(SUM(output),0), COALESCE(SUM(reasoning),0),
  COALESCE(SUM(cache_read),0), COALESCE(SUM(cache_write),0)
FROM m WHERE time_created >= (SELECT month_ms FROM bounds)
UNION ALL
SELECT 'all', COUNT(*), ROUND(COALESCE(SUM(cost),0),6),
  COALESCE(SUM(input),0), COALESCE(SUM(output),0), COALESCE(SUM(reasoning),0),
  COALESCE(SUM(cache_read),0), COALESCE(SUM(cache_write),0)
FROM m;
'#

# Path to the local OpenCode database that stores per-step cost and tokens.
def opencode-go-db [] {
  let override = ($env.OPENCODE_GO_DB? | default "")
  if ($override | is-not-empty) { return $override }
  ($env.HOME? | default "") + "/.local/share/opencode/opencode.db"
}

# Compact token count: 1234 -> "1.2K", 17600000 -> "17.6M", 9.7e9 -> "9.7B".
def opencode-go-compact [value: int] {
  if $value >= 1000000000 { return ($"($value / 1000000000 | math round --precision 1)B") }
  if $value >= 1000000 { return ($"($value / 1000000 | math round --precision 1)M") }
  if $value >= 1000 { return ($"($value / 1000 | math round --precision 1)K") }
  $value | into string
}

# Usage history keyed by window (today, h24, d3, week, month, all), or null
# when sqlite3 or the OpenCode database is unavailable.
def opencode-go-history [] {
  let db = (opencode-go-db)
  if not ($db | path exists) { return null }
  let rows = (try {
    ^sqlite3 -json $"file:($db)?mode=ro" $GO_HISTORY_SQL | from json
  } catch { null })
  if ($rows | is-empty) { return null }
  $rows | reduce --fold {} {|row, acc|
    let entry = {
      cost: ($row.cost | default 0)
      input: ($row.input | default 0)
      output: ($row.output | default 0)
      reasoning: ($row.reasoning | default 0)
      cacheRead: ($row.cache_read | default 0)
      cacheWrite: ($row.cache_write | default 0)
      steps: ($row.steps | default 0)
    }
    $acc | insert $row.period $entry
  }
}

def opencode-go-history-table [history: record] {
  let order = ["today" "h24" "d3" "week" "month" "all"]
  let labels = { today: "Today", h24: "Last 24h", d3: "Last 3d", week: "Last 7d", month: "Last 30d", all: "All time" }
  print ""
  print "Usage history (API-equivalent cost)"
  for id in $order {
    let entry = ($history | get $id)
    let total = ($entry.input + $entry.output + $entry.reasoning + $entry.cacheRead + $entry.cacheWrite)
    let label = ($labels | get $id | fill -a l -w 10 -c " ")
    let steps = ($entry.steps | into string | fill -a r -w 7 -c " ")
    let tokens = (opencode-go-compact $total | fill -a r -w 8 -c " ")
    let money = ("$" + ($entry.cost | math round --precision 2 | into string))
    print $"  ($label) ($steps) steps  ($tokens) tokens  ($money)"
  }
}

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

def opencode-go-pad [value: int] {
  $value | into string | fill -a r -w 2 -c "0"
}

# Start of the monthly window that ends at `end`: the same anchor day in the
# previous calendar month, clamped to that month's last day. Mirrors the
# console's getMonthlyBounds, where the anchor is the subscription day.
def opencode-go-month-start [end: datetime] {
  let utc = ($end | date to-timezone utc)
  let parts = ($utc | format date "%Y %m %d %H %M %S" | split row " ")
  let year = ($parts.0 | into int)
  let month = ($parts.1 | into int)
  let day = ($parts.2 | into int)
  let prev_year = (if $month == 1 { $year - 1 } else { $year })
  let prev_month = (if $month == 1 { 12 } else { $month - 1 })
  let month_start = ($"($year)-(opencode-go-pad $month)-01T00:00:00Z" | into datetime)
  let last_day = (($month_start - 1day) | format date "%d" | into int)
  let start_day = (opencode-go-pad ([$day $last_day] | math min))
  $"($prev_year)-(opencode-go-pad $prev_month)-($start_day)T($parts.3):($parts.4):($parts.5)Z" | into datetime
}

def opencode-go-window-start [window: string, end: datetime, rolling: duration] {
  match $window {
    "rolling" => ($end - $rolling)
    "weekly" => ($end - 7day)
    _ => (opencode-go-month-start $end)
  }
}

# Portion of the window that has already elapsed, 0-100.
def opencode-go-elapsed [start: datetime, end: datetime] {
  let total = (($end - $start) | into int)
  if $total <= 0 { return 100 }
  let passed = (((date now) - $start) | into int)
  let percent = ($passed * 100 / $total | math round | into int)
  if $percent < 0 { return 0 }
  if $percent > 100 { return 100 }
  $percent
}

def opencode-go-annotate-window [entry: record, window: string, rolling: duration] {
  let end = ($entry.resetsAt | into datetime)
  let start = (opencode-go-window-start $window $end $rolling)
  $entry | upsert elapsedPercent (opencode-go-elapsed $start $end)
}

def opencode-go-annotate [row: record, rolling: duration] {
  if not $row.ok { return $row }
  let usage = ($row.usage
    | upsert rolling (opencode-go-annotate-window $row.usage.rolling rolling $rolling)
    | upsert weekly (opencode-go-annotate-window $row.usage.weekly weekly $rolling)
    | upsert monthly (opencode-go-annotate-window $row.usage.monthly monthly $rolling))
  $row | upsert usage $usage
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
    let elapsed = ($usage.elapsedPercent | default 0)
    let time_color = (if $tint { (ansi cyan) } else { "" })
    let time_bar = (opencode-go-bar $elapsed $width $time_color)
    let label = ($window.label | fill -a l -w 13 -c " ")
    let blank = ($"" | fill -w 13 -c " ")
    let percent = ($usage.percent | into string | fill -a r -w 3 -c " ")
    let percent_text = (if $tint { $"($color)($percent)% used(ansi reset)" } else { $"($percent)% used" })
    let resets = (opencode-go-reset ($usage.resetsAt | into datetime))
    let dim = (if $tint { (ansi dark_gray) } else { "" })
    let reset_text = ($dim + "Resets in" + (if $tint { (ansi reset) } else { "" }))
    let limited = (if $usage.status == "rate-limited" {
      if $tint { $"  (ansi red)· limit reached(ansi reset)" } else { "  · limit reached" }
    } else { "" })
    let elapsed_ratio = ($elapsed | into string | fill -a r -w 3 -c " ")
    let elapsed_text = (if $tint { $"($time_color)($elapsed_ratio)% elapsed(ansi reset)" } else { $"($elapsed_ratio)% elapsed" })
    print $"  ($label)  ($bar)  ($percent_text)   ($reset_text) ($resets)($limited)"
    print $"  ($blank)  ($time_bar)  ($elapsed_text)"
  }
}

# Show rolling / weekly / monthly OpenCode Go usage for all saved accounts.
def opencode-go-usage [
  --width (-w): int = 24                 # Width of the usage bars
  --rolling-window (-r): duration = 5hr  # Rolling quota window (the 5-hour limit)
  --binary (-b): string = ""             # opencode CLI binary (default: $OPENCODE_BIN, opencode2, opencode)
  --endpoint (-e): string = ""           # Usage endpoint override
  --json (-j)                            # Print raw usage data as JSON
  --history                              # Include API-equivalent usage history from the local database
  --no-color                             # Disable colored output
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

  let fetched = ($accounts | enumerate | par-each {|entry|
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

  let rows = ($fetched | each {|row| opencode-go-annotate $row $rolling_window })
  let history_data = (if $history { opencode-go-history } else { null })

  if $json {
    if $history {
      return ({ accounts: $rows, history: $history_data } | to json --indent 2)
    }
    return ($rows | to json --indent 2)
  }

  $rows | enumerate | each {|item|
    if $item.index > 0 { print "" }
    opencode-go-account $item.item $width $tint
  } | ignore

  if $history {
    if $history_data == null {
      print ""
      print "(usage history unavailable: sqlite3 or the OpenCode database is missing)"
    } else {
      opencode-go-history-table $history_data
    }
  }
}
