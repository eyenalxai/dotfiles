-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Per-monitor workspaces (hyprsplit): SUPER+1..9 act on the focused display,
-- so each monitor keeps its own independent set of 9 workspaces.
local hyprsplit = require("hyprsplit")

-- Unbind Omarchy's default global workspace keys (SUPER+1..9/0 plus moves).
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
end

-- Rebind 1-9 to the focused monitor's local workspaces.
for workspace = 1, 9 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hyprsplit.dsp.focus({ workspace = workspace }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hyprsplit.dsp.window.move({ workspace = workspace, follow = true }))
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, hyprsplit.dsp.window.move({ workspace = workspace, follow = false }))
end

-- Screenshot on SUPER + SHIFT + S instead of PRINT
-- (SUPER + SHIFT + S was previously bound to Google Maps)
hl.unbind("PRINT")
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Move only the focused window between displays, not the whole workspace.
hl.unbind("SUPER + SHIFT + ALT + LEFT")
hl.unbind("SUPER + SHIFT + ALT + RIGHT")
o.bind("SUPER + SHIFT + ALT + LEFT", "Move window to left monitor", hl.dsp.window.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + RIGHT", "Move window to right monitor", hl.dsp.window.move({ monitor = "r" }))

-- Launch Helium browser
o.bind("SUPER + B", "Helium", { launch = "helium-browser" })

-- Close window with Super + Q instead of Super + W
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- Clipboard manager on Super + Shift + X instead of Super + Ctrl + V
hl.unbind("SUPER + CTRL + V")
hl.unbind("SUPER + SHIFT + X")
o.bind("SUPER + SHIFT + X", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- Dictation (push-to-talk, hold to talk like F9) on Super + Shift + D
hl.unbind("SUPER + SHIFT + D")
o.bind("SUPER + SHIFT + D", "Start dictation (push-to-talk)", "voxtype record start")
o.bind("SUPER + SHIFT + D", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
