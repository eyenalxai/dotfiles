-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Dell on the left, Samsung on the right, aligned at the top.
hl.monitor({ output = "desc:Dell Inc. DELL E2420HS 4VMDM13", mode = "preferred", position = "0x0", scale = "auto" })
hl.monitor({ output = "desc:Samsung Electric Company LS27A600U HNMT901241", mode = "preferred", position = "1920x0", scale = "auto" })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
