// Parsing helpers for the resources bar module.
//
// The module samples Linux /proc in-process (Quickshell FileView) and keeps
// the QML side to presentation, so the sampling math lives here where it can
// be reasoned about — and exercised — on its own.

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

function firstNumber(line) {
  var match = String(line || "").match(/\d+/)
  return match ? Number(match[0]) : 0
}

// KiB → GiB with one decimal, for the RAM tooltip.
function formatGib(kib) {
  return (Number(kib || 0) / 1048576).toFixed(1)
}
