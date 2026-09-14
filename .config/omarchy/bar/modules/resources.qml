import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Resources.js" as Resources

// System resource indicator for one metric, picked per bar entry in
// shell.json:
//
//   { "id": "cpu", "type": "qml", "metric": "cpu",
//     "source": "~/.config/omarchy/bar/modules/resources.qml" }
//   { "id": "ram", "type": "qml", "metric": "ram",
//     "source": "~/.config/omarchy/bar/modules/resources.qml" }
//
// One module definition backs both indicators so the sampling and
// presentation stay in a single place. Left-click opens btop, or focuses it
// when it is already running.
//
// CPU usage is the busy share between two /proc/stat samples; RAM is
// MemTotal - MemAvailable from /proc/meminfo. Both files are read in-process
// through FileView — no helper process and no shell.
BarWidget {
  id: root

  readonly property string metric: String(setting("metric", "cpu"))
  readonly property bool isRam: metric === "ram"
  // nf-fa-microchip / nf-md-memory.
  readonly property string glyph: isRam ? "󰍛" : ""
  readonly property bool ready: isRam ? ramTotalKib > 0 : cpuReady
  readonly property string valueLabel: ready ? Math.round(percent) + "%" : "--%"
  readonly property real percent: isRam ? ramPercent : cpuPercent
  readonly property string tooltip: {
    var hint = " · Click for btop"
    if (!ready) return (isRam ? "RAM" : "CPU") + hint
    if (isRam)
      return "RAM " + ramPercent.toFixed(1) + "% ("
        + Resources.formatGib(ramUsedKib) + " / " + Resources.formatGib(ramTotalKib) + " GiB)" + hint
    return "CPU " + cpuPercent.toFixed(1) + "%" + hint
  }

  property real cpuPercent: 0
  property real ramPercent: 0
  property real ramUsedKib: 0
  property real ramTotalKib: 0
  // CPU usage needs two samples: the first only establishes a baseline.
  property var previousCpuSample: null
  property bool cpuReady: false

  function openBtop() {
    if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
  }

  function sampleCpu(raw) {
    var sample = Resources.parseCpuStat(raw)
    if (!sample) return
    if (root.previousCpuSample) {
      root.cpuPercent = Resources.cpuUsage(root.previousCpuSample, sample)
      root.cpuReady = true
    }
    root.previousCpuSample = sample
  }

  function sampleRam(raw) {
    var memory = Resources.parseMeminfo(raw)
    // A short read mid-update must not flip the indicator to 100%.
    if (memory.total <= 0 || memory.available <= 0) return
    root.ramTotalKib = memory.total
    root.ramUsedKib = memory.total - memory.available
    root.ramPercent = root.ramUsedKib / memory.total * 100
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // A vertical bar has no room for "42% 󰍛" across its width, so there the
    // glyph carries the indicator alone and the tooltip keeps the number.
    text: root.vertical ? root.glyph : root.valueLabel + " " + root.glyph
    slotSize: root.vertical ? Style.bar.iconSlot : Style.bar.iconSlot * 2
    tooltipText: root.tooltip
    onPressed: function(button) {
      if (button === Qt.LeftButton) root.openBtop()
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      // Sample only the metric this entry paints; the other file is dead work.
      if (root.isRam) memFile.reload()
      else statFile.reload()
    }
  }

  FileView {
    id: statFile
    path: "/proc/stat"
    onLoaded: root.sampleCpu(statFile.text())
  }

  FileView {
    id: memFile
    path: "/proc/meminfo"
    onLoaded: root.sampleRam(memFile.text())
  }
}
