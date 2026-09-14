import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Resources.js" as Resources

// Bar indicator for one system resource, picked per bar entry in shell.json:
//
//   { "id": "cpu", "type": "qml", "metric": "cpu",
//     "source": "~/.config/omarchy/bar/modules/resources.qml" }
//   { "id": "ram", "type": "qml", "metric": "ram",
//     "source": "~/.config/omarchy/bar/modules/resources.qml" }
//
// The badge is icon-only; the tooltip carries the numbers. One module
// definition backs both indicators so the sampling and presentation stay in a
// single place. Left-click opens btop, or focuses it when it is already
// running.
//
// CPU usage is the busy share between two /proc/stat samples; RAM is
// MemTotal - MemAvailable from /proc/meminfo. Both files are read in-process
// through FileView — no helper process and no shell.
//
// The RAM instance also guards against memory exhaustion: once free memory
// has stayed below lowMemoryThresholdPercent for lowMemorySustainMs it posts
// a critical notification, refreshes it in place at most once per
// lowMemoryNotificationIntervalMs, and clears it when memory recovers. The
// notification's click action opens btop.
BarWidget {
  id: root

  readonly property string metric: String(setting("metric", "cpu"))
  readonly property bool isRam: metric === "ram"
  // nf-fa-microchip / nf-md-memory.
  readonly property string glyph: isRam ? "󰍛" : ""
  readonly property bool ready: isRam ? ramTotalKib > 0 : cpuReady
  readonly property real percent: isRam ? ramPercent : cpuPercent
  readonly property string tooltip: {
    var hint = " · Click for btop"
    if (!ready) return (isRam ? "RAM" : "CPU") + hint
    if (isRam)
      return "RAM " + ramPercent.toFixed(1) + "% · "
        + Resources.formatGib(ramAvailableKib) + " GiB available" + hint
    return "CPU " + cpuPercent.toFixed(1) + "%" + hint
  }

  // Memory guard thresholds: warn under 10% available, ignore blips shorter
  // than a few samples, and refresh the toast (same as the low-battery
  // warning) at most every five minutes.
  readonly property int lowMemoryThresholdPercent: 10
  readonly property int lowMemorySustainMs: 3 * 1000
  readonly property int lowMemoryNotificationIntervalMs: 5 * 60 * 1000

  property real cpuPercent: 0
  property real ramPercent: 0
  property real ramAvailableKib: 0
  property real ramTotalKib: 0
  // CPU usage needs two samples: the first only establishes a baseline.
  property var previousCpuSample: null
  property bool cpuReady: false
  // Memory guard state: when the current low streak began, when the toast was
  // last posted, its notification id (so refreshes replace it in place), and
  // whether a toast is currently up.
  property double memoryLowSince: 0
  property double lastMemoryNotificationAt: 0
  property int memoryNotificationId: 0
  property bool memoryWarned: false

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
    // A short read mid-update must not flip the indicator or the guard.
    if (memory.total <= 0 || memory.available <= 0) return
    root.ramTotalKib = memory.total
    root.ramAvailableKib = memory.available
    root.ramPercent = (memory.total - memory.available) / memory.total * 100
    root.checkLowMemory()
  }

  function checkLowMemory() {
    if (!Resources.isMemoryLow(root.ramAvailableKib, root.ramTotalKib, root.lowMemoryThresholdPercent)) {
      root.memoryLowSince = 0
      root.clearLowMemoryNotification()
      return
    }

    var now = Date.now()
    if (root.memoryLowSince === 0) root.memoryLowSince = now
    // Only a sustained drop is worth a critical alert; a transient dip is not.
    if (now - root.memoryLowSince < root.lowMemorySustainMs) return
    if (!Resources.notificationIntervalElapsed(root.lastMemoryNotificationAt, now, root.lowMemoryNotificationIntervalMs)) return

    root.lastMemoryNotificationAt = now
    root.sendLowMemoryNotification()
  }

  function sendLowMemoryNotification() {
    if (memoryNotifyProc.running) return
    var command = ["omarchy-notification-send", "-p", "-u", "critical", "-g", root.glyph]
    if (root.memoryNotificationId > 0) command = command.concat(["-r", String(root.memoryNotificationId)])
    command = command.concat([
      "Memory is almost full",
      Resources.formatGib(root.ramAvailableKib) + " GiB available (" + Math.round(root.ramPercent) + "% used)",
      "--exec", "omarchy-launch-or-focus-tui", "btop"
    ])
    memoryNotifyProc.command = command
    root.memoryWarned = true
    memoryNotifyProc.running = true
  }

  function clearLowMemoryNotification() {
    if (!root.memoryWarned || memoryNotifyProc.running || memoryDismissProc.running) return
    root.memoryWarned = false
    root.memoryNotificationId = 0
    memoryDismissProc.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
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
    path: root.isRam ? "" : "/proc/stat"
    onLoaded: root.sampleCpu(statFile.text())
  }

  FileView {
    id: memFile
    path: root.isRam ? "/proc/meminfo" : ""
    onLoaded: root.sampleRam(memFile.text())
  }

  Process {
    id: memoryNotifyProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var id = parseInt(String(text || "").trim(), 10)
        if (!isNaN(id) && id > 0) root.memoryNotificationId = id
      }
    }
  }

  Process {
    id: memoryDismissProc
    command: ["omarchy-notification-dismiss", "Memory is almost full"]
  }
}
