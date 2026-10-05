import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// OpenCode Go usage for every saved account, plus API-equivalent usage history.
//
// Clicking the bar icon opens a panel in the same shape as the Wi-Fi and
// Bluetooth panels: a hero, every saved account with one row per quota window
// (usage bar over window-elapsed bar, like the `opencode-go-usage` terminal
// view), and a usage-history section with period buttons. History comes from
// the local OpenCode database: every completed step stores the API price its
// tokens would have cost, so the money figure is what the same usage would
// have cost at API rates. The layout keeps four accounts on screen.
//
// Data comes from `opencode-go-usage --json --history` through usage.nu.
// Left-click opens the panel, middle-click refreshes, right-click opens the
// full terminal view. Keys: 1-6 pick a history period, left/right cycle it,
// up/down scroll, r refreshes. Set `refreshIntervalSec` in shell.json to poll
// slower or faster (default 300, minimum 30).
//
// The bar icon only turns urgent when every saved account is out of quota:
// the `opencode-go-failover` OpenCode plugin parks a limited account and
// switches to another one, so a single limited account is not a warning.
Panel {
  id: root
  moduleName: "ulezot.opencode-go"
  ipcTarget: "ulezot.opencode-go"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color track: Style.selectedFillFor(foreground, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // nf-md-robot.
  readonly property string mark: "\udb81\udea9"
  readonly property string pluginDir: (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/ulezot.opencode-go"

  property var accounts: []
  property var history: null
  property var fit: null
  property bool loading: false
  property string error: ""

  // Selected usage-history window ("today", "h24", ...); driven by the chips
  // in the USAGE HISTORY section.
  property string period: "today"

  // Countdowns read this instead of Date.now() so an open panel keeps telling
  // the truth while it sits there.
  property double nowMs: Date.now()

  readonly property var activeAccount: {
    for (var i = 0; i < accounts.length; i++)
      if (accounts[i] && accounts[i].active) return accounts[i]
    return null
  }
  // Combined monthly usage across every account that reports a monthly window:
  // the mean of the per-account monthly percentages, so with equal quotas it is
  // the share of the combined monthly allowance that is used.
  readonly property real combinedMonthly: {
    var total = 0
    var count = 0
    for (var i = 0; i < accounts.length; i++) {
      var a = accounts[i]
      if (!a || !a.ok || !a.usage || !a.usage.monthly) continue
      total += Number(a.usage.monthly.percent) / 100
      count++
    }
    return count > 0 ? total / count : -1
  }

  // Fit mark for the combined monthly allowance: nf-fa-check when the CLI's
  // projection says the allowance lasts until the next account refill,
  // nf-fa-exclamation-triangle when it would run dry first, and nothing when
  // the CLI has no samples to project from (see opencode-go-usage.nu).
  readonly property string monthlyFitMark: {
    if (!fit || !fit.monthly) return ""
    return fit.monthly.ok ? " \uf00c" : " \uf071"
  }
  readonly property var periods: [
    { value: "today", label: "Today", tooltip: "Today, since local midnight" },
    { value: "h24", label: "24h", tooltip: "Rolling last 24 hours" },
    { value: "d3", label: "3d", tooltip: "Rolling last 3 days" },
    { value: "week", label: "Week", tooltip: "Rolling last 7 days" },
    { value: "month", label: "Month", tooltip: "Rolling last 30 days" },
    { value: "all", label: "All", tooltip: "All time" }
  ]
  readonly property var historyRow: history ? history[period] : null
  readonly property var historyTotals: totalsFor(historyRow)

  // Warning state: every saved account is out of quota, so the failover
  // plugin has nowhere to switch and requests will start failing. Anything
  // less than that is handled by the plugin, so it is not a warning.
  readonly property bool alarming: {
    if (accounts.length === 0) return false
    for (var i = 0; i < accounts.length; i++)
      if (!accountLimited(accounts[i])) return false
    return true
  }
  readonly property string errorText: error

  // Always on the bar: data problems surface in the panel, they must never
  // make the widget vanish (an empty account list used to hide it).
  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  // "OpenCode Go | Two" reads as "Two" in the panel; labels without the pipe
  // keep their full name.
  function shortName(item) {
    if (!item) return ""
    var parts = String(item.label || "").split("|")
    var tail = parts[parts.length - 1].trim()
    return tail !== "" ? tail : String(item.label || "")
  }

  function windowRows(a) {
    if (!a || !a.ok || !a.usage) return []
    var defs = ["rolling", "weekly", "monthly"]
    var titles = ["Rolling", "Weekly", "Monthly"]
    var out = []
    for (var i = 0; i < defs.length; i++) {
      var entry = a.usage[defs[i]]
      if (!entry) continue
      out.push({
        title: titles[i],
        percent: Number(entry.percent) / 100,
        elapsed: Number(entry.elapsedPercent || 0) / 100,
        resetAt: String(entry.resetsAt || ""),
        limited: entry.status === "rate-limited"
      })
    }
    return out
  }

  // An account is out of quota when any of its windows reports a limit. The
  // failover plugin parks such an account and keeps working on another one.
  function accountLimited(a) {
    var list = windowRows(a)
    for (var i = 0; i < list.length; i++)
      if (list[i].limited) return true
    return false
  }

  function resetMsFor(w) {
    if (!w || w.resetAt === "") return -1
    var ms = new Date(w.resetAt).getTime()
    return isFinite(ms) ? ms - root.nowMs : -1
  }

  function formatDuration(ms) {
    if (!(ms > 0)) return "now"
    var minutes = Math.floor(ms / 60000)
    var hours = Math.floor(minutes / 60)
    var days = Math.floor(hours / 24)
    if (days > 0) return days + "d " + (hours % 24) + "h"
    if (hours > 0) return hours + "h " + (minutes % 60) + "m"
    return Math.max(1, minutes) + "m"
  }

  function cyclePeriod(dx) {
    var idx = 0
    for (var i = 0; i < periods.length; i++)
      if (periods[i].value === period) idx = i
    period = periods[(idx + dx + periods.length) % periods.length].value
  }

  function selectPeriod(index) {
    if (index >= 0 && index < periods.length) period = periods[index].value
  }

  // 17600000 -> "17.6M", 9700000000 -> "9.7B", 790 -> "790".
  function formatTokens(value) {
    var n = Number(value) || 0
    if (n >= 1000000000) return trimZero((n / 1000000000).toFixed(1)) + "B"
    if (n >= 1000000) return trimZero((n / 1000000).toFixed(1)) + "M"
    if (n >= 1000) return trimZero((n / 1000).toFixed(1)) + "K"
    return String(Math.round(n))
  }

  function trimZero(text) {
    return text.endsWith(".0") ? text.substring(0, text.length - 2) : text
  }

  // 8.4217 -> "$8.42", 1234.5 -> "$1,234.50".
  function formatMoney(value) {
    var n = Number(value) || 0
    var whole = Math.floor(Math.abs(n))
    var cents = Math.round((Math.abs(n) - whole) * 100)
    if (cents === 100) { whole += 1; cents = 0 }
    var text = String(whole).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
    return (n < 0 ? "-$" : "$") + text + "." + (cents < 10 ? "0" : "") + cents
  }

  // Token totals for a history window: fresh input, generated output
  // (reasoning included), and cache traffic.
  function totalsFor(row) {
    var input = row ? Number(row.input) || 0 : 0
    var output = row ? (Number(row.output) || 0) + (Number(row.reasoning) || 0) : 0
    var cached = row ? (Number(row.cacheRead) || 0) + (Number(row.cacheWrite) || 0) : 0
    return { tokens: input + output + cached, input: input, output: output, cached: cached }
  }

  function historyDetail(row) {
    var t = totalsFor(row)
    return "in " + formatTokens(t.input) + " · out " + formatTokens(t.output)
      + " · cached " + formatTokens(t.cached)
  }

  function refresh() {
    if (usageProc.running) return
    loading = true
    usageProc.running = true
  }

  function openFullView() {
    if (bar) bar.run("omarchy-launch-floating-terminal-with-presentation nu " + pluginDir + "/show.nu")
  }

  function applyUsage(raw) {
    loading = false
    var trimmed = String(raw || "").trim()
    if (trimmed === "") return
    try {
      var data = JSON.parse(trimmed)
      if (Array.isArray(data)) {
        accounts = data
        fit = null
      } else if (data && Array.isArray(data.accounts)) {
        accounts = data.accounts
        history = data.history || null
        fit = data.fit || null
      } else {
        throw new Error("unexpected shape")
      }
      // An empty list almost always means the CLI could not read the accounts
      // (service hiccup), not that they are gone. Report it rather than
      // silently going blank.
      error = accounts.length === 0 ? "No OpenCode Go accounts found." : ""
      nowMs = Date.now()
    } catch (e) {
      error = "Could not parse `opencode-go-usage --json --history` output."
    }
  }

  function footerText() {
    if (history === null)
      return "r refresh · right-click terminal view"
    return "1-6/←→ period · r refresh · right-click full view"
  }

  onOpenedChanged: if (opened) {
    nowMs = Date.now()
    if (panelFlick) panelFlick.contentY = 0
    refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }
  }

  Process {
    id: usageProc
    command: ["timeout", "-k", "5", "25", "nu", root.pluginDir + "/usage.nu"]
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
      if (exitCode !== 0) {
        root.error = String(usageErr.text || "").trim() || ("Usage command exited with " + exitCode)
        retryTimer.restart()
      }
    }
  }

  Timer {
    id: retryTimer
    // One quick retry after a failure, so a transient hiccup does not leave
    // the widget stale until the next scheduled refresh.
    interval: 60000
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: Math.max(30, Number(root.setting("refreshIntervalSec", 300))) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // A stale "resets in 2h" on an open panel is worse than a timer.
  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.mark
    active: root.alarming
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.openFullView()
      else if (buttonCode === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(780))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (dx !== 0) {
          root.cyclePeriod(dx)
        } else if (dy !== 0) {
          panelFlick.contentY = root.clamp(panelFlick.contentY + dy * Style.space(56), 0,
                                           Math.max(0, panelFlick.contentHeight - panelFlick.height))
        }
      }
      onActivateRequested: root.refresh()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t.length === 1 && t >= "1" && t <= "6") {
          root.selectPeriod(Number(t) - 1)
        } else if (t === "r" || t === "R") {
          root.refresh()
          root.nowMs = Date.now()
        }
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(8)

          // ---------- Hero ----------
          PanelHero {
            width: parent.width
            title: "OpenCode Go"
            meta: root.activeAccount
              ? root.shortName(root.activeAccount) + " · active"
              : root.accounts.length + " accounts"
            detail: root.combinedMonthly >= 0 ? Math.round(root.combinedMonthly * 100) + "%" + root.monthlyFitMark : ""
            foreground: root.foreground
            fontFamily: root.fontFamily

            iconComponent: Component {
              Item {
                width: Style.font.display
                height: Style.font.display

                Text {
                  anchors.centerIn: parent
                  text: root.mark
                  color: root.alarming ? root.urgent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                }
              }
            }
          }

          // ---------- Unavailable ----------
          BorderSurface {
            visible: root.errorText !== ""
            width: parent.width
            implicitHeight: statusText.implicitHeight + Style.spacing.lg * 2
            color: root.alpha(root.urgent, 0.10)
            borderSpec: Border.flat(root.alpha(root.urgent, 0.35), 1)
            radius: Style.cornerRadius

            Text {
              id: statusText
              textFormat: Text.PlainText
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(10)
              text: root.errorText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }

          // ---------- Accounts ----------
          PanelSeparator {
            visible: accountsSection.visible
            foreground: root.foreground
          }

          Column {
            id: accountsSection
            visible: root.accounts.length > 0
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              width: parent.width
              text: "ACCOUNTS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.accounts

              Column {
                required property var modelData
                required property int index

                width: accountsSection.width
                spacing: Style.space(6)

                PanelSeparator {
                  visible: index > 0
                  width: parent.width
                  foreground: root.foreground
                  strength: 0.08
                }

                AccountBlock {
                  width: parent.width
                  item: modelData
                }
              }
            }
          }

          // ---------- Usage history ----------
          PanelSeparator {
            visible: historySection.visible
            foreground: root.foreground
          }

          Column {
            id: historySection
            visible: root.history !== null
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              width: parent.width
              text: "USAGE HISTORY"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            ButtonGroup {
              id: periodGroup
              options: root.periods
              value: root.period
              focusable: false
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              onChanged: function(v) { root.period = v }
            }

            RowLayout {
              width: parent.width
              spacing: Style.space(6)

              Text {
                textFormat: Text.PlainText
                text: root.formatTokens(root.historyTotals.tokens)
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                Layout.alignment: Qt.AlignBaseline
              }

              Text {
                textFormat: Text.PlainText
                text: "tokens"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                Layout.alignment: Qt.AlignBaseline
              }

              Item { Layout.fillWidth: true }

              Text {
                textFormat: Text.PlainText
                text: root.formatMoney(root.historyRow ? root.historyRow.cost : 0)
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                Layout.alignment: Qt.AlignBaseline
              }

              Text {
                textFormat: Text.PlainText
                text: "saved"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                Layout.alignment: Qt.AlignBaseline
              }
            }

            RowLayout {
              width: parent.width
              spacing: Style.space(6)

              Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: root.historyDetail(root.historyRow)
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                text: "vs API prices"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: text !== ""
            width: parent.width
            topPadding: Style.space(2)
            text: root.errorText !== "" ? "" : root.footerText()
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
          }
        }
      }
    }
  }

  // One saved account: its name and active marker, then a row per window.
  component AccountBlock: Column {
    id: accountBlock
    property var item: null

    readonly property var windows: root.windowRows(accountBlock.item)
    readonly property bool limited: root.accountLimited(accountBlock.item)
    // Only paint an account as alarming when nothing can take over from it.
    readonly property bool hot: accountBlock.limited && root.alarming

    spacing: Style.space(4)

    Item {
      width: parent.width
      implicitHeight: Math.max(nameText.implicitHeight, activeText.implicitHeight)

      Text {
        id: nameText
        textFormat: Text.PlainText
        text: root.shortName(accountBlock.item)
        color: accountBlock.hot ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
        anchors.left: parent.left
        anchors.right: activeText.left
        anchors.rightMargin: Style.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: activeText
        textFormat: Text.PlainText
        visible: accountBlock.item && accountBlock.item.active
        text: "● active"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        textFormat: Text.PlainText
        visible: !(accountBlock.item && accountBlock.item.active) && accountBlock.item && !accountBlock.item.ok
        text: "unavailable"
        color: root.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Text {
      textFormat: Text.PlainText
      visible: accountBlock.item && !accountBlock.item.ok
      width: parent.width
      text: accountBlock.item ? String(accountBlock.item.error || "Usage unavailable") : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    Repeater {
      model: accountBlock.windows

      WindowRow {
        required property var modelData
        width: accountBlock.width
        window: modelData
      }
    }
  }

  // Two stacked bars per window: usage on top, window elapsed underneath,
  // matching the terminal view.
  component WindowRow: Column {
    id: windowRow
    property var window: null

    readonly property bool limited: !!windowRow.window && windowRow.window.limited
    // Red only once every account is out; while failover has somewhere to go,
    // a limited window is information, not a warning.
    readonly property bool alarming: windowRow.limited && root.alarming

    spacing: Style.space(2)

    RowLayout {
      width: parent.width
      spacing: Style.space(6)

      Text {
        textFormat: Text.PlainText
        Layout.preferredWidth: Style.space(48)
        Layout.alignment: Qt.AlignVCenter
        text: windowRow.window ? windowRow.window.title : ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }

      Meter {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        value: windowRow.window ? windowRow.window.percent : 0
        alarming: windowRow.alarming
      }

      Text {
        textFormat: Text.PlainText
        Layout.preferredWidth: Style.space(74)
        Layout.alignment: Qt.AlignVCenter
        text: windowRow.window ? Math.round(windowRow.window.percent * 100) + "% used" : ""
        color: windowRow.alarming ? root.urgent : (windowRow.limited ? root.dim : root.foreground)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignRight
      }

      Text {
        textFormat: Text.PlainText
        Layout.preferredWidth: Style.space(88)
        Layout.alignment: Qt.AlignVCenter
        text: {
          if (!windowRow.window) return ""
          if (windowRow.window.limited) return "limit reached"
          var ms = root.resetMsFor(windowRow.window)
          return ms > 0 ? "resets " + root.formatDuration(ms) : ""
        }
        color: windowRow.alarming ? root.urgent : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignRight
      }
    }

    RowLayout {
      width: parent.width
      spacing: Style.space(6)

      Item { Layout.preferredWidth: Style.space(48) }

      Meter {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        value: windowRow.window ? windowRow.window.elapsed : 0
        fillColor: root.alpha(root.foreground, 0.45)
      }

      Text {
        textFormat: Text.PlainText
        Layout.preferredWidth: Style.space(74)
        Layout.alignment: Qt.AlignVCenter
        text: windowRow.window ? Math.round(windowRow.window.elapsed * 100) + "% elapsed" : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignRight
      }

      Item { Layout.preferredWidth: Style.space(88) }
    }
  }

  // A thin rounded bar. Usage fills with the foreground (or urgent when the
  // window is nearly spent); elapsed fills in a lighter tone behind it.
  component Meter: Item {
    id: meter
    property real value: -1
    property bool alarming: false
    property color fillColor: alarming ? root.urgent : root.foreground
    property real thickness: Math.max(Style.space(3), 3)

    implicitHeight: thickness

    Rectangle {
      id: barTrack
      anchors.fill: parent
      radius: height / 2
      color: root.track
    }

    Rectangle {
      anchors.left: barTrack.left
      anchors.verticalCenter: barTrack.verticalCenter
      height: barTrack.height
      radius: barTrack.radius
      width: barTrack.width * root.clamp(meter.value, 0, 1)
      color: meter.fillColor

      Behavior on width {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }
  }
}
