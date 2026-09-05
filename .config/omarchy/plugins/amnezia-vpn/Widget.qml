import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "amnezia-vpn"

  property bool vpnActive: false

  function refresh() {
    if (!checkProc.running) checkProc.running = true
  }

  function launchAmnezia() {
    if (root.bar) root.bar.run("omarchy launch or focus AmneziaVPN AmneziaVPN")
  }

  Process {
    id: checkProc
    command: ["sh", "-c", "ip -o link show dev amn0 2>/dev/null | grep -Eq '<([^>]*,)?UP(,|>)' || ip -o link show dev tun2 2>/dev/null | grep -Eq '<([^>]*,)?UP(,|>)'"]
    onExited: function(exitCode) {
      root.vpnActive = exitCode === 0
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
    tooltipText: root.vpnActive ? "Amnezia VPN: Connected" : "Amnezia VPN: Disconnected"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        root.refresh()
      } else {
        root.launchAmnezia()
      }
    }
  }
}
