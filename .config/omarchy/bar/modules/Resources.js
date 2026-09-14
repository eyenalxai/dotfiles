// Parsing and policy helpers for the resources bar module.
//
// CPU and RAM are sampled in-process from /proc (Quickshell FileView); disk
// usage comes from btrfs or df, whichever the mount understands. The QML side
// stays presentation-only so the parsing, the math and the low-memory
// notification policy can be reasoned about — and exercised — on their own.

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

// Used share (percent) of a total/free pair, clamped to 0..100, or -1 when a
// sample is unusable.
function usedPercent(totalKib, freeKib) {
  if (!(totalKib > 0) || !(freeKib >= 0)) return -1
  return Math.max(0, Math.min(100, (1 - freeKib / totalKib) * 100))
}

// btrfs's own numbers from `btrfs filesystem usage -b <mount>`, as KiB:
//   Device size:                  92381642752
//   Free (estimated):             45678735360  (min: 24392642560)
// "Free (estimated)" is the space btrfs can still hand out once the chunk
// profiles are paid for; the optional min is the worst-case figure when the
// remaining profiles constrain allocation (DUP/RAID metadata). Returns null
// when the report is missing or unreadable.
function parseBtrfsUsage(raw) {
  var lines = String(raw || "").split("\n")
  var totalKib = 0
  var freeKib = -1
  var minFreeKib = -1

  for (var i = 0; i < lines.length; i++) {
    var device = lines[i].match(/^\s*Device size:\s*(\d+)/)
    if (device) {
      totalKib = Number(device[1]) / 1024
      continue
    }
    var free = lines[i].match(/^\s*Free \(estimated\):\s*(\d+)(?:\s*\(min:\s*(\d+)\))?/)
    if (free) {
      freeKib = Number(free[1]) / 1024
      if (free[2]) minFreeKib = Number(free[2]) / 1024
    }
  }

  if (!(totalKib > 0) || freeKib < 0) return null
  return { totalKib: totalKib, freeKib: freeKib, minFreeKib: minFreeKib }
}

// `df -B1 --output=size,avail <mount>` fallback for non-btrfs mounts: a header
// plus one row of bytes. Returns KiB, or null when there is no usable row.
function parseDf(raw) {
  var lines = String(raw || "").trim().split("\n")
  if (lines.length < 2) return null
  var fields = lines[lines.length - 1].trim().split(/\s+/)
  if (fields.length < 2) return null
  var totalKib = Number(fields[0]) / 1024
  var freeKib = Number(fields[1]) / 1024
  if (!(totalKib > 0) || !(freeKib >= 0)) return null
  return { totalKib: totalKib, freeKib: freeKib, minFreeKib: -1 }
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
    usedPercent: usedPercent,
    parseBtrfsUsage: parseBtrfsUsage,
    parseDf: parseDf,
    notificationIntervalElapsed: notificationIntervalElapsed,
    formatGib: formatGib
  }
}
