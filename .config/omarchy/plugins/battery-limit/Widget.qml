import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "battery-limit"

  property int endThreshold: 100
  readonly property bool isLimited: endThreshold > 0 && endThreshold <= 80
  readonly property bool batteryPresent: UPower.displayDevice && UPower.displayDevice.isPresent
  property bool popupOpen: false

  function close() {
    popupOpen = false
  }

  function refresh() {
    if (!readProc.running) readProc.running = true
  }

  function setLimit(enable) {
    if (setProc.running) return
    setProc.targetState = enable
    root.endThreshold = enable ? 80 : 100
    setProc.running = true
  }

  function toggleLimit() {
    setLimit(!root.isLimited)
  }

  IpcHandler {
    target: "battery-limit"

    function toggle(): void {
      root.toggleLimit()
    }

    function enable(): void {
      root.setLimit(true)
    }

    function disable(): void {
      root.setLimit(false)
    }

    function refresh(): void {
      root.refresh()
    }
  }

  Process {
    id: readProc
    command: [
      "sh", "-c",
      "cat /sys/class/power_supply/macsmc-battery/charge_control_end_threshold 2>/dev/null || cat /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null || echo 100"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var val = parseInt((text || "").trim(), 10)
        if (!isNaN(val) && val > 0) {
          root.endThreshold = val
        }
      }
    }
  }

  Process {
    id: setProc
    property bool targetState: false
    command: [
      "sh", "-c",
      "dev=$(upower -e 2>/dev/null | grep -iE '/devices/battery' | head -n 1); " +
      "if [ -n \"$dev\" ]; then " +
      "  gdbus call --system --dest org.freedesktop.UPower --object-path \"$dev\" --method org.freedesktop.UPower.Device.EnableChargeThreshold " + (setProc.targetState ? "true" : "false") + " >/dev/null; " +
      "fi"
    ]
    onExited: function(code) {
      root.refresh()
    }
  }

  Timer {
    interval: 4000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  visible: root.batteryPresent
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.isLimited ? "󰚥 80%" : "󰚥 100%"
    fontSize: Style.font.caption
    dimmed: !root.isLimited
    tooltipText: root.isLimited
      ? "Battery Limit: 80% (Active)\nClick: Controls · Right/Middle-click: Allow 100%\nScroll: Adjust"
      : "Battery Limit: 100% (Full charge)\nClick: Controls · Right/Middle-click: Limit to 80%\nScroll: Adjust"
    onPressed: function(btn) {
      if (btn === Qt.RightButton || btn === Qt.MiddleButton) {
        root.toggleLimit()
      } else {
        root.popupOpen = !root.popupOpen
      }
    }
    onWheelMoved: function(delta) {
      if (delta > 0 && !root.isLimited) root.setLimit(true)
      else if (delta < 0 && root.isLimited) root.setLimit(false)
    }
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen && root.batteryPresent
    contentWidth: popup.fittedContentWidth(Style.space(260))
    contentHeight: popup.fittedContentHeight(popupColumn.implicitHeight)

    Column {
      id: popupColumn
      anchors.fill: parent
      spacing: Style.space(12)

      PanelSectionHeader {
        text: "BATTERY CHARGE LIMIT"
        foreground: root.bar ? root.bar.foreground : Color.foreground
      }

      ButtonGroup {
        width: parent.width
        options: [
          { value: "80", label: "80% Limit", icon: "󰚥" },
          { value: "100", label: "100% Full", icon: "󰁹" }
        ]
        value: root.isLimited ? "80" : "100"
        onChanged: function(v) {
          if (v === "80" && !root.isLimited) root.setLimit(true)
          else if (v === "100" && root.isLimited) root.setLimit(false)
        }
      }

      Text {
        textFormat: Text.PlainText
        text: root.isLimited
          ? "Charging is capped at 80% to preserve battery lifespan and reduce wear."
          : "Charging is allowed to reach 100% for maximum runtime."
        color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        width: parent.width
      }
    }
  }
}
