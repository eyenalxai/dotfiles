-- Main Hyprland configuration (Lua).
--
-- The old hyprlang .conf files are backed up in hyprlang-backup/.
-- hyprlock.conf and hyprsunset.conf remain in their original format because
-- those tools do not use the Hyprland Lua config.

require("monitors")
require("input")
require("bindings")
require("autostart")
require("windows")
require("looknfeel")

hl.config({
  debug = {
    disable_logs = false,
  },
})
