import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "ulezot.updates"
  ipcTarget: "ulezot.updates"
  // manageIpc: false so the single IpcHandler below can also expose refresh().
  manageIpc: false

  // ---------------------------------------------------------------- state
  //
  // The two sources are checked independently: a failed AUR query must not
  // hide a healthy repository result, and the bar can show the mirror count
  // as soon as checkupdates returns.

  property var systemUpdates: []
  property var aurUpdates: []
  property var pendingSystem: []
  property var pendingAur: []
  property string systemState: "idle"  // idle | checking | ok | error
  property string aurState: "idle"
  property string systemError: ""
  property string aurError: ""
  property double lastChecked: 0
  property double lastAttempt: 0
  property double lastUpgradeMs: 0
  property double nowMs: Date.now()

  readonly property int systemCount: systemUpdates.length
  readonly property int aurCount: aurUpdates.length
  readonly property int totalCount: systemCount + aurCount
  readonly property bool hasUpdates: totalCount > 0
  readonly property bool checking: systemState === "checking" || aurState === "checking"
  readonly property bool failed: systemState === "error" || aurState === "error"
  readonly property var repoGroups: Model.groupUpdates(systemUpdates, aurUpdates)

  // Muted when nothing is waiting. With updates, the bar's normal icon color
  // until the last upgrade is three days old, then urgent.
  readonly property double overdueAfterMs: 3 * 24 * 60 * 60 * 1000
  readonly property bool overdue: hasUpdates && lastUpgradeMs > 0 && (nowMs - lastUpgradeMs) >= overdueAfterMs

  readonly property int refreshIntervalSec: Math.max(300, Number(setting("refreshIntervalSec", 3600)) || 3600)
  readonly property int staleAfterMs: 10 * 60 * 1000

  readonly property string updatesScript: {
    var resolved = Qt.resolvedUrl("updates.sh").toString().replace(/^file:\/\//, "")
    if (resolved && resolved.length > 0) return resolved
    return Quickshell.env("HOME") + "/.config/omarchy/plugins/ulezot.updates/updates.sh"
  }

  // ------------------------------------------------------------ bar label
  //
  // A single update icon. The count and the split live in the panel; the bar
  // only needs to say "something is waiting" and whether it has been waiting
  // too long.

  // --------------------------------------------------------------- status

  readonly property string heroMeta: {
    if (root.checking && root.totalCount === 0) return "CHECKING FOR UPDATES"
    if (root.failed && root.totalCount === 0) return "CHECK FAILED"
    if (root.totalCount === 0) return "UP TO DATE"

    var systemLabel = root.systemState === "error" && root.systemCount === 0 ? "–" : String(root.systemCount)
    var aurLabel = root.aurState === "error" && root.aurCount === 0 ? "–" : String(root.aurCount)
    return systemLabel + " SYSTEM · " + aurLabel + " AUR"
  }

  readonly property string statusNote: {
    if (root.checking) return "Checking for updates…"

    if (root.failed) {
      var errors = []
      if (root.systemState === "error" && root.systemError !== "") errors.push(root.systemError)
      if (root.aurState === "error" && root.aurError !== "") errors.push(root.aurError)
      if (errors.length > 0) return errors.join(" · ")
      return "Last check failed. Check your network connection and try again."
    }

    var when = Model.relativeTime(root.lastChecked, root.nowMs)
    var upgrade = Model.relativeTime(root.lastUpgradeMs, root.nowMs)
    var parts = []
    if (when !== "") parts.push("Checked " + when)
    if (upgrade !== "") parts.push("last upgrade " + upgrade)
    return parts.join(" · ")
  }

  readonly property string tooltipText: {
    if (root.checking && root.totalCount === 0) return "Checking for package updates…"
    if (root.failed && root.totalCount === 0) return "Update check failed\nClick for details"

    var when = Model.relativeTime(root.lastChecked, root.nowMs)
    var upgrade = Model.relativeTime(root.lastUpgradeMs, root.nowMs)
    var footnote = []
    if (when !== "") footnote.push("checked " + when)
    if (upgrade !== "") footnote.push("last upgrade " + upgrade)
    var tail = footnote.length > 0 ? "\n" + footnote.join(" · ") : ""

    if (root.totalCount === 0) return "System and AUR packages are up to date" + tail

    var systemLabel = root.systemState === "error" && root.systemCount === 0
      ? "repository check failed"
      : root.systemCount + " system"
    var aurLabel = root.aurState === "error" && root.aurCount === 0
      ? "AUR check failed"
      : root.aurCount + " AUR"
    return root.totalCount + " package updates: " + systemLabel + " · " + aurLabel + tail
      + "\nClick for details · right-click to refresh"
  }

  function scrollBy(dy) {
    if (dy === 0) return
    var view = scrollArea.contentItem
    var limit = Math.max(0, view.contentHeight - scrollArea.height)
    view.contentY = Math.max(0, Math.min(limit, view.contentY + dy * Style.space(48)))
  }

  function checkSystem(force) {
    if (systemProc.running) return
    root.pendingSystem = []
    root.systemState = "checking"
    root.systemError = ""
    root.lastAttempt = Date.now()
    var args = [root.updatesScript, "--system"]
    if (force === true) args.push("--force")
    systemProc.command = args
    systemProc.running = true
  }

  function checkAur(force) {
    if (aurProc.running) return
    root.pendingAur = []
    root.aurState = "checking"
    root.aurError = ""
    root.lastAttempt = Date.now()
    var args = [root.updatesScript, "--aur"]
    if (force === true) args.push("--force")
    aurProc.command = args
    aurProc.running = true
  }

  function refresh(force) {
    checkSystem(force === true)
    checkAur(force === true)
    checkLastUpgrade()
  }

  function checkLastUpgrade() {
    if (!lastUpgradeProc.running) lastUpgradeProc.running = true
  }

  function launchUpdate() {
    if (!root.hasUpdates) return
    if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation omarchy-update")
    postUpdateRefresh.restart()
    root.close()
  }

  IpcHandler {
    target: "ulezot.updates"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh(true) }
  }

  onOpenedChanged: {
    if (!opened) return
    root.nowMs = Date.now()
    if (Date.now() - root.lastAttempt >= root.staleAfterMs) root.refresh(false)
  }

  // --------------------------------------------------------------- checks

  Process {
    id: systemProc
    command: []

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.pendingSystem = Model.parseUpdates(text)
        // If the process exited before this stream finished, the exit handler
        // already collected pendingSystem; keep the UI consistent either way.
        if (root.systemState === "ok") root.systemUpdates = root.pendingSystem
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.systemError = Model.firstLine(text)
    }

    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.systemUpdates = root.pendingSystem
        root.systemState = "ok"
        root.lastChecked = Date.now()
        root.nowMs = Date.now()
      } else {
        root.systemState = "error"
        if (root.systemError === "") root.systemError = "Could not reach the package mirrors."
      }
    }
  }

  Process {
    id: aurProc
    command: []

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.pendingAur = Model.parseUpdates(text)
        if (root.aurState === "ok") root.aurUpdates = root.pendingAur
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.aurError = Model.firstLine(text)
    }

    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.aurUpdates = root.pendingAur
        root.aurState = "ok"
        root.lastChecked = Date.now()
        root.nowMs = Date.now()
      } else {
        root.aurState = "error"
        if (root.aurError === "") root.aurError = "Could not reach the AUR."
      }
    }
  }

  Process {
    id: lastUpgradeProc
    command: [root.updatesScript, "--last-upgrade"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var epoch = parseInt(String(text).trim(), 10)
        if (isFinite(epoch) && epoch > 0) root.lastUpgradeMs = epoch * 1000
      }
    }
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh(false)
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.nowMs = Date.now()
  }

  // A finished omarchy-update drops the counts; re-read them once the dust has
  // settled instead of waiting out the full refresh interval.
  Timer {
    id: postUpdateRefresh
    interval: 10 * 60 * 1000
    repeat: false
    onTriggered: root.refresh(true)
  }

  // ----------------------------------------------------------- bar button

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏕"
    slotSize: Style.bar.statusSlot
    foreground: root.hasUpdates ? root.bar.foreground : Color.muted
    active: root.overdue
    tooltipText: root.tooltipText

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.refresh(true)
      else if (buttonCode === Qt.MiddleButton) root.launchUpdate()
      else root.toggle()
    }
  }

  // ---------------------------------------------------------------- panel

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(body.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) { root.scrollBy(dy) }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        var key = text.toLowerCase()
        if (key === "r") root.refresh(true)
        else if (key === "u") root.launchUpdate()
      }

      ScrollView {
        id: scrollArea
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: body.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        Binding {
          target: scrollArea.contentItem
          property: "interactive"
          value: body.implicitHeight > scrollArea.height
        }

        Column {
          id: body
          width: scrollArea.availableWidth
          spacing: Style.space(14)

          PanelHero {
            width: parent.width
            iconComponent: Component {
              Text {
                text: "󰏕"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.display
              }
            }
            title: "Updates"
            meta: root.heroMeta
            detail: root.totalCount > 0 ? String(root.totalCount) : ""
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            id: actions
            width: parent.width
            spacing: Style.space(6)

            Button {
              width: root.hasUpdates ? (parent.width - parent.spacing) / 2 : 0
              visible: root.hasUpdates
              iconText: "󰏕"
              iconSize: Style.font.icon
              text: "Update all"
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
              bordered: true
              active: root.hasUpdates
              tooltipText: "Open a terminal and run omarchy-update"
              onClicked: root.launchUpdate()
            }

            Button {
              width: root.hasUpdates ? (parent.width - parent.spacing) / 2 : parent.width
              iconText: "󰑐"
              iconSize: Style.font.icon
              iconSpinning: root.checking
              text: root.checking ? "Checking…" : "Refresh"
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
              bordered: true
              tooltipText: "Check the repositories and AUR now"
              onClicked: root.refresh(true)
            }
          }

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: root.statusNote
            visible: text !== ""
            color: root.failed ? root.bar.foreground : Qt.darker(root.bar.foreground, 1.4)
            opacity: root.failed ? 1.0 : 0.8
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          // Empty / checking / failed state. Kept above the list so the result
          // doesn't jump down when the first package group arrives.
          Column {
            width: parent.width
            visible: root.totalCount === 0
            spacing: Style.space(6)
            topPadding: Style.space(10)
            bottomPadding: Style.space(6)

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: root.failed ? "󰀨" : (root.checking ? "󰑐" : "󰄬")
              color: Qt.darker(root.bar.foreground, 1.25)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
            }

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
              text: root.failed
                ? "Could not check for updates"
                : (root.checking ? "Checking for updates…" : "Everything is up to date")
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              text: root.failed
                ? "Fix the error above, then refresh."
                : (root.checking
                  ? "This can take a few seconds while the mirrors answer."
                  : "No official-repository or AUR packages are waiting.")
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }

          Repeater {
            model: root.repoGroups

            delegate: Column {
              id: group
              required property var modelData
              required property int index
              width: body.width
              spacing: Style.space(6)

              PanelSeparator {
                visible: group.index > 0
                width: parent.width
                foreground: root.bar.foreground
              }

              PanelSectionHeader {
                width: parent.width
                text: group.modelData.repo.toUpperCase() + " · " + group.modelData.count
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
              }

              Repeater {
                model: group.modelData.packages

                delegate: Item {
                  id: updateRow
                  required property var modelData
                  width: group.width
                  height: rowName.implicitHeight

                  Text {
                    id: rowName
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width * 0.6)
                    textFormat: Text.PlainText
                    text: updateRow.modelData.name
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
                  }

                  Text {
                    id: rowVersion
                    anchors.left: rowName.right
                    anchors.leftMargin: Style.space(10)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    textFormat: Text.PlainText
                    text: updateRow.modelData.newVersion
                    color: Qt.darker(root.bar.foreground, 1.35)
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideMiddle
                  }

                  MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                  }

                  PanelToolTip {
                    visible: rowMouse.containsMouse
                    text: updateRow.modelData.name + "  "
                      + updateRow.modelData.oldVersion + " → " + updateRow.modelData.newVersion
                    fontFamily: root.bar.fontFamily
                  }
                }
              }
            }
          }

          Text {
            width: parent.width
            visible: root.hasUpdates
            textFormat: Text.PlainText
            text: "r refresh · u update · esc close"
            color: Qt.darker(root.bar.foreground, 1.5)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
            topPadding: Style.space(4)
          }
        }
      }
    }
  }
}
