import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// OpenCode Go usage for every saved account, on the bar left of the battery.
//
// The badge is an nf-md-robot mark that turns urgent when a window is near or
// at its limit. The tooltip expands each window into a usage bar over a
// window-elapsed bar, so usage can be compared against how far the window has
// already run -- the same numbers the `opencode-go-usage` Nushell command
// prints in a terminal.
//
// Data comes from that command through usage.sh. Left-click or scroll cycles
// accounts, middle-click refreshes, right-click opens the full view in a
// floating terminal. Set `refreshIntervalSec` in shell.json to poll slower or
// faster (default 300, minimum 30).
BarWidget {
  id: root
  moduleName: "ulezot.opencode-go"

  readonly property string pluginDir: (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/ulezot.opencode-go"
  readonly property string mark: "\udb81\udea9"
  readonly property int meterWidth: 16

  property var accounts: []
  property int selected: 0
  property bool pinned: false
  property bool loading: false
  property string error: ""

  readonly property var account: accounts.length > 0 ? accounts[Math.max(0, Math.min(selected, accounts.length - 1))] : null

  readonly property bool alarming: {
    if (!account || !account.ok || !account.usage) return false
    var ids = ["rolling", "weekly", "monthly"]
    for (var i = 0; i < ids.length; i++) {
      var entry = account.usage[ids[i]]
      if (entry && (entry.status === "rate-limited" || Number(entry.percent) >= 80)) return true
    }
    return false
  }

  function accountPercent(item, id) {
    if (!item || !item.usage || !item.usage[id]) return "?"
    return Number(item.usage[id].percent)
  }

  function resetText(resetsAt) {
    var end = Date.parse(resetsAt)
    if (isNaN(end)) return ""
    var delta = end - Date.now()
    if (delta <= 0) return "now"
    var minutes = Math.floor(delta / 60000)
    var days = Math.floor(minutes / 1440)
    var hours = Math.floor((minutes % 1440) / 60)
    if (days >= 1) return days + "d " + hours + "h"
    if (hours >= 1) return hours + "h " + (minutes % 60) + "m"
    if (minutes >= 1) return minutes + "m"
    return "<1m"
  }

  function meter(percent) {
    var clamped = Math.max(0, Math.min(100, Number(percent) || 0))
    var filled = Math.round(clamped * meterWidth / 100)
    var out = ""
    for (var i = 0; i < meterWidth; i++) out += i < filled ? "█" : "░"
    return out
  }

  function padLeft(text, width) {
    var value = String(text)
    while (value.length < width) value = " " + value
    return value
  }

  function padRight(text, width) {
    var value = String(text)
    while (value.length < width) value = value + " "
    return value
  }

  function windowLine(id, entry) {
    if (!entry) return padRight(id, 7)
    var elapsed = entry.elapsedPercent === undefined ? 0 : entry.elapsedPercent
    return padRight(id, 7) + "  " + meter(entry.percent) + "  "
      + padLeft(entry.percent, 3) + "% used · "
      + padLeft(elapsed, 3) + "% elapsed · resets in "
      + resetText(entry.resetsAt)
  }

  readonly property string tooltipText: {
    if (error !== "") return "OpenCode Go\n" + error
    if (!account) return loading ? "OpenCode Go\nloading…" : "OpenCode Go\nno saved accounts"
    if (!account.ok) return account.label + "\n" + (account.error || "usage unavailable")

    var lines = []
    var head = account.label + (account.active ? "  ● active" : "")
    if (accounts.length > 1) head += "  (" + (selected + 1) + "/" + accounts.length + ")"
    lines.push(head)
    lines.push(windowLine("rolling", account.usage.rolling))
    lines.push(windowLine("weekly", account.usage.weekly))
    lines.push(windowLine("monthly", account.usage.monthly))
    for (var i = 0; i < accounts.length; i++) {
      if (i === selected) continue
      var item = accounts[i]
      if (!item.ok || !item.usage) lines.push(item.label + "  unavailable")
      else lines.push(item.label + "  " + accountPercent(item, "rolling") + "·"
        + accountPercent(item, "weekly") + "·" + accountPercent(item, "monthly"))
    }
    lines.push(accounts.length > 1
      ? "left-click / scroll: account · middle: refresh · right: full view"
      : "middle-click: refresh · right-click: full view")

    // Pad to a common width: the tooltip centers each line, so equal widths
    // keep the meters in the same columns.
    var width = 0
    for (var k = 0; k < lines.length; k++) width = Math.max(width, lines[k].length)
    for (var m = 0; m < lines.length; m++) lines[m] = padRight(lines[m], width)
    return lines.join("\n")
  }

  function refresh() {
    if (usageProc.running) return
    loading = true
    usageProc.running = true
  }

  function next() {
    if (accounts.length > 1) {
      pinned = true
      selected = (selected + 1) % accounts.length
    } else {
      refresh()
    }
  }

  function openFullView() {
    if (bar) bar.run("omarchy-launch-floating-terminal-with-presentation " + pluginDir + "/show.sh")
  }

  function applyUsage(raw) {
    loading = false
    var trimmed = String(raw || "").trim()
    if (trimmed === "") return
    try {
      var data = JSON.parse(trimmed)
      if (!Array.isArray(data)) throw new Error("expected a list")
      accounts = data
      if (!pinned) {
        var active = -1
        for (var i = 0; i < data.length; i++) {
          if (data[i] && data[i].active) { active = i; break }
        }
        selected = active >= 0 ? active : 0
      }
      if (selected >= data.length) selected = 0
      error = ""
    } catch (e) {
      error = "could not parse usage output"
    }
  }

  Timer {
    interval: Math.max(30, Number(setting("refreshIntervalSec", 300))) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "ulezot.opencode-go"
    function refresh(): string { root.broadcast("refresh"); return "ok" }
    function next(): string { root.broadcast("next"); return "ok" }
  }

  Process {
    id: usageProc
    command: ["sh", root.pluginDir + "/usage.sh"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyUsage(text)
    }
    stderr: StdioCollector {
      id: usageErr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.loading = false
      if (exitCode !== 0)
        root.error = String(usageErr.text || "").trim() || ("usage command exited with " + exitCode)
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.mark
    active: root.error !== "" || root.alarming
    dimmed: root.loading && root.accounts.length === 0
    tooltipText: root.tooltipText
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.openFullView()
      else if (buttonCode === Qt.MiddleButton) root.refresh()
      else root.next()
    }
    onWheelMoved: function(delta) {
      if (delta === 0) return
      root.next()
    }
  }
}
