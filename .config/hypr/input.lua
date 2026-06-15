--[[
  Input device configuration.

  Equivalent to the old input.conf.
--]]

hl.config({
  input = {
    kb_layout = "us,ru",
    kb_options = "grp:caps_toggle",

    repeat_rate = 40,
    repeat_delay = 600,

    numlock_by_default = true,

    touchpad = {
      scroll_factor = 0.4,
    },
  },
})

-- Scroll faster in the terminal
hl.window_rule({
  name = "terminal-scroll-speed",
  match = { tag = "terminal" },
  scroll_touchpad = 1.5,
})
