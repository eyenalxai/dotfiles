// Pure helpers for the package-update widget. updates.sh emits one TSV row
// per package; everything below turns that into the grouped rows the panel
// renders. Kept free of QML so it can be exercised with node.

function parseUpdates(raw) {
  var updates = []
  var lines = String(raw || "").split("\n")

  for (var i = 0; i < lines.length; i++) {
    if (!lines[i]) continue
    var parts = lines[i].split("\t")
    if (parts.length < 4) continue

    var repo = parts[0].trim()
    var name = parts[1].trim()
    var oldVersion = parts[2].trim()
    var newVersion = parts[3].trim()
    if (!repo || !name || !newVersion) continue

    updates.push({
      repo: repo,
      name: name,
      oldVersion: oldVersion,
      newVersion: newVersion
    })
  }

  updates.sort(function(a, b) {
    return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
  })

  return updates
}

function groupUpdates(systemUpdates, aurUpdates) {
  var groups = {}
  var system = Array.isArray(systemUpdates) ? systemUpdates : []
  var aur = Array.isArray(aurUpdates) ? aurUpdates : []

  for (var i = 0; i < system.length; i++) {
    var repo = String(system[i].repo || "system")
    if (!groups[repo]) groups[repo] = []
    groups[repo].push(system[i])
  }

  // AUR is a different source, not just another mirror, so it always sits
  // last instead of sorting in with the repository names.
  var repos = Object.keys(groups).sort()
  var result = []
  for (var r = 0; r < repos.length; r++) {
    result.push({
      repo: repos[r],
      count: groups[repos[r]].length,
      packages: groups[repos[r]]
    })
  }

  if (aur.length > 0) {
    result.push({ repo: "AUR", count: aur.length, packages: aur })
  }

  return result
}

function relativeTime(thenMs, nowMs) {
  var then = Number(thenMs)
  var now = Number(nowMs)
  if (!isFinite(then) || then <= 0 || !isFinite(now)) return ""

  var seconds = Math.max(0, Math.floor((now - then) / 1000))
  if (seconds < 60) return "just now"

  var minutes = Math.floor(seconds / 60)
  if (minutes < 60) return minutes + " min ago"

  var hours = Math.floor(minutes / 60)
  if (hours < 24) return hours + " h ago"

  return Math.floor(hours / 24) + " d ago"
}

function firstLine(raw) {
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (line) return line
  }
  return ""
}

if (typeof module !== "undefined") {
  module.exports = {
    parseUpdates: parseUpdates,
    groupUpdates: groupUpdates,
    relativeTime: relativeTime,
    firstLine: firstLine
  }
}
