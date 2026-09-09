function clampIndex(index, length) {
  if (length <= 0) return 0
  return Math.max(0, Math.min(length - 1, index))
}

function selectProfileIndex(index, delta, profiles) {
  var values = Array.isArray(profiles) ? profiles : []
  if (values.length === 0) return 0
  return clampIndex(index + delta, values.length)
}

function parseKeyValue(raw) {
  var next = {}
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var idx = lines[i].indexOf("\t")
    if (idx <= 0) continue
    var key = lines[i].substring(0, idx)
    var val = lines[i].substring(idx + 1).trim()
    if (key === "rate") {
      val = val.replace(/^-/, "")
    }
    next[key] = val
  }
  return next
}

function parseProfiles(raw, previousIndex) {
  var lines = String(raw || "").split("\n")
  var list = []
  var active = ""
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (!line) continue
    var parts = line.split("\t")
    list.push(parts[0])
    if (parts[1] === "1") active = parts[0]
  }
  return {
    profiles: list,
    activeProfile: active,
    profileIndex: clampIndex(previousIndex || 0, list.length)
  }
}

function profileIcon(name) {
  if (name === "power-saver") return "󰌪"
  if (name === "balanced") return "󰊚"
  if (name === "performance") return "󰓅"
  return "󰂄"
}

function batteryFraction(device) {
  return device && device.isPresent ? Math.max(0, Math.min(1, device.percentage)) : 0
}

function isDeviceDischarging(device, onBattery, states, batteryInfo) {
  var d = device || {}
  var s = states || {}
  if (batteryInfo && batteryInfo.state) {
    if (batteryInfo.state === "discharging") return true
    if (batteryInfo.state === "charging" || batteryInfo.state === "holding") return false
  }
  if (d.isPresent && d.state === s.Discharging) return true
  if (d.isPresent && d.state === s.Charging) return false
  return !!onBattery
}

function chargeThresholdActive(device, onBattery, states, batteryInfo) {
  var d = device || {}
  var s = states || {}
  if (batteryInfo && batteryInfo.threshold_end && Number(batteryInfo.threshold_end) >= 100) return false
  if (batteryInfo && batteryInfo.state === "holding") return true
  if (isDeviceDischarging(device, onBattery, states, batteryInfo)) return false
  if (!(d && d.isPresent && !onBattery)) return false

  var fraction = batteryFraction(d)
  if (d.state === s.Discharging) return false
  if (d.state === s.PendingCharge) return true
  if (d.state === s.FullyCharged && fraction < 0.99) return true
  if (d.state !== s.Charging || fraction >= 0.99) return false

  return Number(d.changeRate || 0) <= 0.2 || Number(d.timeToFull || 0) >= 8 * 60 * 60
}

function isDeviceCharging(device, onBattery, states, batteryInfo) {
  var d = device || {}
  var s = states || {}
  if (onBattery) return false
  if (chargeThresholdActive(device, onBattery, states, batteryInfo)) return false
  if (isDeviceDischarging(device, onBattery, states, batteryInfo)) return false

  if (batteryInfo && batteryInfo.state) {
    if (batteryInfo.state === "charging") return true
    if (batteryInfo.state === "discharging" || batteryInfo.state === "holding") return false
  }

  if (d.isPresent) {
    if (d.state === s.Charging) return true
    if (d.state === s.Discharging || d.state === s.FullyCharged || d.state === s.PendingCharge) return false
  }

  return !onBattery && Number(d.changeRate || 0) > 0.2 && batteryFraction(d) < 0.99
}

function batteryIcon(device, onBattery, states, batteryInfo) {
  var d = device || {}
  if (!d.isPresent) return ""

  var chargingIcons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
  var defaultIcons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
  var index = Math.max(0, Math.min(9, Math.floor(d.percentage * 10)))

  if (d.state === states.FullyCharged && d.percentage >= 0.99) return "󰂅"
  if (isDeviceCharging(device, onBattery, states, batteryInfo)) return chargingIcons[index]
  return defaultIcons[index]
}

function modeLabel(device, onBattery, states, batteryInfo) {
  var d = device || {}
  if (!d.isPresent) return ""

  var percentage = d.isPresent ? d.percentage : 0
  if (chargeThresholdActive(device, onBattery, states, batteryInfo)) return "Threshold"
  if (isDeviceDischarging(device, onBattery, states, batteryInfo)) {
    return onBattery ? "On battery" : "Discharging"
  }
  if (percentage >= 0.99 && !isDeviceCharging(device, onBattery, states, batteryInfo)) return "Fully charged"
  if (isDeviceCharging(device, onBattery, states, batteryInfo)) return "Charging"
  return onBattery ? "On battery" : "Discharging"
}

if (typeof module !== "undefined") {
  module.exports = {
    clampIndex: clampIndex,
    selectProfileIndex: selectProfileIndex,
    parseKeyValue: parseKeyValue,
    parseProfiles: parseProfiles,
    profileIcon: profileIcon,
    batteryFraction: batteryFraction,
    isDeviceDischarging: isDeviceDischarging,
    chargeThresholdActive: chargeThresholdActive,
    isDeviceCharging: isDeviceCharging,
    batteryIcon: batteryIcon,
    modeLabel: modeLabel
  }
}
