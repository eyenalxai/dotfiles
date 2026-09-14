// Parsing and policy helpers for the resources bar module.
//
// The module samples Linux /proc in-process (Quickshell FileView) and keeps
// the QML side to presentation, so the sampling math and the low-memory
// notification policy live here where they can be reasoned about — and
// exercised — on their own.

// One sample of the aggregate CPU counters from /proc/stat's `cpu` line:
//   cpu user nice system idle iowait irq softirq steal [guest guest_nice]
// guest/guest_nice are already included in user/nice, so they are excluded
// from the total. Returns null when the line is missing or malformed.
function parseCpuStat(raw) {
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (line.indexOf("cpu ") !== 0) continue
    var fields = line.trim().split(/\s+/)
    if (fields.length < 5) return null
    var total = 0
    for (var f = 1; f < fields.length && f <= 8; f++) total += Number(fields[f]) || 0
    return { total: total, idle: (Number(fields[4]) || 0) + (Number(fields[5]) || 0) }
  }
  return null
}

// Busy share between two consecutive parseCpuStat() samples, in percent.
function cpuUsage(previous, current) {
  if (!previous || !current) return 0
  var total = current.total - previous.total
  if (!(total > 0)) return 0
  var idle = current.idle - previous.idle
  return Math.max(0, Math.min(100, (1 - idle / total) * 100))
}

// MemTotal and MemAvailable from /proc/meminfo, in KiB.
function parseMeminfo(raw) {
  var lines = String(raw || "").split("\n")
  var memory = { total: 0, available: 0 }
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (line.indexOf("MemTotal:") === 0) memory.total = firstNumber(line)
    else if (line.indexOf("MemAvailable:") === 0) memory.available = firstNumber(line)
    if (memory.total > 0 && memory.available > 0) break
  }
  return memory
}

// Available memory as a percentage of total, or -1 when a sample is unusable.
function memoryAvailablePercent(availableKib, totalKib) {
  if (!(totalKib > 0) || !(availableKib >= 0)) return -1
  return availableKib / totalKib * 100
}

// True while free memory sits at or below `thresholdPercent` of total.
function isMemoryLow(availableKib, totalKib, thresholdPercent) {
  var percent = memoryAvailablePercent(availableKib, totalKib)
  return percent >= 0 && percent <= thresholdPercent
}

// True when a repeat notification is allowed: never within `intervalMs` of the
// previous one; always when there was none, or the clock jumped backwards.
function notificationIntervalElapsed(lastNotifyTime, now, intervalMs) {
  var last = typeof lastNotifyTime === "number" ? lastNotifyTime : 0
  var current = typeof now === "number" ? now : Date.now()
  var interval = typeof intervalMs === "number" ? intervalMs : 0
  if (!(last > 0)) return true
  if (!(current >= last)) return true
  return current - last >= interval
}

function firstNumber(line) {
  var match = String(line || "").match(/\d+/)
  return match ? Number(match[0]) : 0
}

// KiB → GiB with one decimal, for tooltips and notification bodies.
function formatGib(kib) {
  return (Number(kib || 0) / 1048576).toFixed(1)
}

// Keep the helpers importable outside the shell for tests, like the power
// plugin's Model.js does.
if (typeof module !== "undefined") {
  module.exports = {
    parseCpuStat: parseCpuStat,
    cpuUsage: cpuUsage,
    parseMeminfo: parseMeminfo,
    memoryAvailablePercent: memoryAvailablePercent,
    isMemoryLow: isMemoryLow,
    notificationIntervalElapsed: notificationIntervalElapsed,
    formatGib: formatGib
  }
}
