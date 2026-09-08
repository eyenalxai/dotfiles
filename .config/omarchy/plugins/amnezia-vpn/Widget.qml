import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "amnezia-vpn"

  property bool amneziaActive: false
  property bool happActive: false
  readonly property bool vpnActive: amneziaActive || happActive

  function refresh() {
    if (!checkProc.running) checkProc.running = true
  }

  function launchAmnezia() {
    if (root.bar) root.bar.run("omarchy launch or focus AmneziaVPN AmneziaVPN")
  }

  function launchHapp() {
    if (root.bar) root.bar.run("omarchy launch or focus Happ happ")
  }

  function handleLeftClick() {
    if (root.happActive && !root.amneziaActive) {
      root.launchHapp()
    } else if (root.amneziaActive && !root.happActive) {
      root.launchAmnezia()
    } else {
      root.launchAmnezia()
    }
  }

  Process {
    id: checkProc
    command: [
      "sh", "-c",
      "amn=0; happ=0; " +
      "(ip -o link show dev amn0 2>/dev/null | grep -Eq '<([^>]*,)?UP(,|>)' || ip -o link show dev tun2 2>/dev/null | grep -Eq '<([^>]*,)?UP(,|>)' ) && amn=1; " +
      "ip -o link show dev happ-xray 2>/dev/null | grep -Eq '<([^>]*,)?UP(,|>)' && happ=1; " +
      "echo \"$amn $happ\""
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const parts = (text || "").trim().split(/\s+/)
        if (parts.length >= 2) {
          root.amneziaActive = parts[0] === "1"
          root.happActive = parts[1] === "1"
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vpnActive ? "󰕥" : ""
    useActiveColor: false
    dimmed: !root.vpnActive
    tooltipText: {
      if (root.amneziaActive && root.happActive) {
        return "VPN Connected: Amnezia & Happ"
      } else if (root.happActive) {
        return "Happ: Connected"
      } else if (root.amneziaActive) {
        return "Amnezia VPN: Connected"
      } else {
        return "VPN: Disconnected"
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        root.refresh()
      } else if (buttonCode === Qt.MiddleButton) {
        root.launchHapp()
      } else {
        root.handleLeftClick()
      }
    }
  }
}
