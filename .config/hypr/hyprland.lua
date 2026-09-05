-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Per-monitor workspaces (hyprsplit): each display gets its own 1..5 instead
-- of sharing one global workspace list. See ~/.config/hypr/plugins/hyprsplit.
package.path = package.path
  .. ";" .. os.getenv("HOME") .. "/.config/hypr/plugins/?.lua"
  .. ";" .. os.getenv("HOME") .. "/.config/hypr/plugins/?/init.lua"

local hyprsplit = require("hyprsplit")
hyprsplit.config({
  num_workspaces = 9,
  persistent_workspaces = true,
})
-- Dell (HDMI-A-2, left) gets workspaces 1-9; Samsung (HDMI-A-1, right) gets 10-18.
-- monitor_priority() appends, so reset first to stay idempotent across `hyprctl reload`.
hyprsplit.monitor_priority_list = {}
hyprsplit.monitor_priority({ "HDMI-A-2", "HDMI-A-1" })

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
