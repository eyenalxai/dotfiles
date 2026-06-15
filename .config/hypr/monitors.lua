--[[
  Monitor configuration, environment variables and per-workspace monitor binding.

  Equivalent to the old monitors.conf.
--]]

local theme = require("theme").load()

-- 1x setup for 1080p/1440p low-resolution displays.
hl.env("GDK_SCALE", "1")

-- Left (secondary): Dell 1080p
hl.monitor({
  output = "HDMI-A-2",
  mode = "preferred",
  position = "0x0",
  scale = 1,
})

-- Right (primary): Samsung 1440p
hl.monitor({
  output = "HDMI-A-1",
  mode = "preferred",
  position = "1920x0",
  scale = 1,
  vrr = 1,
})

-- Pin workspaces to monitors ("two sets" of 1-7).
-- Right/primary monitor (HDMI-A-1): workspaces 1-7
for id = 1, 7 do
  hl.workspace_rule({
    workspace = tostring(id),
    monitor = "HDMI-A-1",
    default = id == 1,
  })
end

-- Left/secondary monitor (HDMI-A-2): workspaces 8-14
for id = 8, 14 do
  hl.workspace_rule({
    workspace = tostring(id),
    monitor = "HDMI-A-2",
    default = id == 8,
  })
end
