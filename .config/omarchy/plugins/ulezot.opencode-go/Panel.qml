import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// OpenCode Go usage for every saved account.
//
// Clicking the bar icon opens a panel in the same shape as the Wi-Fi and
// Bluetooth panels: a hero, then every saved account with one row per quota
// window. Each window shows two bars -- usage over window elapsed -- like the
// `opencode-go-usage` terminal view, so usage can be read against the clock at
// a glance. The layout is compact enough to keep four accounts on screen.
//
// Data comes from the `opencode-go-usage` Nushell command through usage.sh.
// Left-click opens the panel, middle-click refreshes, right-click opens the
// full terminal view. Set `refreshIntervalSec` in shell.json to poll slower or
// faster (default 300, minimum 30).
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
  property bool loading: false
  property string error: ""

  // Countdowns read this instead of Date.now() so an open panel keeps telling
  // the truth while it sits there.
  property double nowMs: Date.now()

  readonly property var activeAccount: {
    for (var i = 0; i < accounts.length; i++)
      if (accounts[i] && accounts[i].active) return accounts[i]
    return null
  }
  readonly property var activeBinding: bindingWindow(activeAccount)
  readonly property bool alarming: {
    for (var i = 0; i < accounts.length; i++)
      if (accountAlarming(accounts[i])) return true
    return false
  }
  readonly property string errorText: error

  visible: accounts.length > 0 || errorText !== "" || loading
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

  function windowAlarming(w) {
    return !!w && (w.limited || w.percent >= 0.8)
  }

  function accountAlarming(a) {
    var list = windowRows(a)
    for (var i = 0; i < list.length; i++)
      if (windowAlarming(list[i])) return true
    return false
  }

  function bindingWindow(a) {
    var best = null
    var list = windowRows(a)
    for (var i = 0; i < list.length; i++)
      if (!best || list[i].percent > best.percent) best = list[i]
    return best
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

  function refresh() {
    if (usageProc.running) return
    loading = true
    usageProc.running = true
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
      error = ""
      nowMs = Date.now()
    } catch (e) {
      error = "Could not parse `opencode-go-usage --json` output."
    }
  }

  function footerText() {
    var hints = ["r refresh", "right-click terminal view"]
    return hints.join(" · ")
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
        root.error = String(usageErr.text || "").trim() || ("Usage command exited with " + exitCode)
    }
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
        if (dy !== 0)
          panelFlick.contentY = root.clamp(panelFlick.contentY + dy * Style.space(56), 0,
                                           Math.max(0, panelFlick.contentHeight - panelFlick.height))
      }
      onActivateRequested: root.refresh()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") {
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
            detail: root.activeBinding ? Math.round(root.activeBinding.percent * 100) + "%" : ""
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
    readonly property bool hot: root.accountAlarming(accountBlock.item)

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

    readonly property bool alarming: root.windowAlarming(windowRow.window)

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
        color: windowRow.alarming ? root.urgent : root.foreground
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
        color: windowRow.window && windowRow.window.limited ? root.urgent : root.dim
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
