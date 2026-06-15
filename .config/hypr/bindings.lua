--[[
  Keybindings.

  Equivalent to the old bindings.conf.
--]]

local HOME = os.getenv("HOME") or ""
local terminal = "uwsm app -- " .. (os.getenv("TERMINAL") or "")
local browser = "uwsm app -- " .. (os.getenv("BROWSER") or "")
local editor = "uwsm app -- " .. (os.getenv("EDITOR") or "")

local function workspace_1to7(action, id)
  return HOME .. "/.local/share/bin/hypr-workspace-1to7 " .. action .. " " .. id
end

-- Application bindings
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal), { description = "Terminal" })
hl.bind(
  "SUPER + SHIFT + F",
  hl.dsp.exec_cmd("uwsm app -- " .. (os.getenv("TERMINAL") or "") .. " -e yazi"),
  { description = "File manager" }
)
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser), { description = "Browser" })
hl.bind(
  "SUPER + SHIFT + ALT + B",
  hl.dsp.exec_cmd(browser .. " --private"),
  { description = "Browser (private)" }
)
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(editor), { description = "Editor" })
hl.bind(
  "SUPER + SHIFT + T",
  hl.dsp.exec_cmd([[bash -lc "~/.local/share/bin/theme-menu > /tmp/theme-menu.log 2>&1"]]),
  { description = "Theme menu" }
)
hl.bind(
  "SUPER + SHIFT + slash",
  hl.dsp.exec_cmd("uwsm app -- 1password"),
  { description = "Passwords" }
)
hl.bind(
  "SUPER + SHIFT + L",
  hl.dsp.exec_cmd("pidof hyprlock || hyprlock"),
  { description = "Lock screen" }
)
hl.bind(
  "SUPER + SHIFT + X",
  hl.dsp.exec_cmd("uwsm app -- ghostty --class=com.kopa.kopa -e kopa")
)
hl.bind(
  "SUPER + Q",
  hl.dsp.window.close({ window = "active" }),
  { description = "Close active window" }
)
hl.bind(
  "SUPER + SHIFT + W",
  hl.dsp.exec_cmd("pkill waybar || uwsm app -- waybar"),
  { description = "Toggle waybar" }
)

-- Walker launcher
hl.bind(
  "SUPER + space",
  hl.dsp.exec_cmd("walker --width 644 --maxheight 300 --minheight 300"),
  { description = "Launch apps" }
)

-- Move focus with SUPER + arrow keys
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "l" }), { description = "Move window focus left" })
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }), { description = "Move window focus right" })
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "u" }), { description = "Move window focus up" })
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "d" }), { description = "Move window focus down" })

-- Focus monitors (so workspace switching targets that display)
hl.bind("SUPER + CTRL + Left", hl.dsp.focus({ monitor = "l" }), { description = "Focus left monitor" })
hl.bind("SUPER + CTRL + Right", hl.dsp.focus({ monitor = "r" }), { description = "Focus right monitor" })

-- Switch workspaces with SUPER + [1-9; 0]
for id = 1, 7 do
  local code = "code:" .. (9 + id) -- 1 is keycode 10, 2 is 11 ... 7 is 16
  hl.bind(
    "SUPER + " .. code,
    hl.dsp.exec_cmd(workspace_1to7("focus", id)),
    { description = "Switch to workspace " .. id }
  )
end

-- Direct access to global workspaces 8-10
hl.bind("SUPER + code:17", hl.dsp.focus({ workspace = "8" }), { description = "Switch to workspace 8" })
hl.bind("SUPER + code:18", hl.dsp.focus({ workspace = "9" }), { description = "Switch to workspace 9" })
hl.bind("SUPER + code:19", hl.dsp.focus({ workspace = "10" }), { description = "Switch to workspace 10" })

-- Move active window to a workspace with SUPER + SHIFT + [1-9; 0]
for id = 1, 7 do
  local code = "code:" .. (9 + id)
  hl.bind(
    "SUPER + SHIFT + " .. code,
    hl.dsp.exec_cmd(workspace_1to7("move", id)),
    { description = "Move window to workspace " .. id }
  )
end

-- Direct access to global workspaces 8-10
hl.bind(
  "SUPER + SHIFT + code:17",
  hl.dsp.window.move({ workspace = "8" }),
  { description = "Move window to workspace 8" }
)
hl.bind(
  "SUPER + SHIFT + code:18",
  hl.dsp.window.move({ workspace = "9" }),
  { description = "Move window to workspace 9" }
)
hl.bind(
  "SUPER + SHIFT + code:19",
  hl.dsp.window.move({ workspace = "10" }),
  { description = "Move window to workspace 10" }
)

-- Move active window silently to a workspace with SUPER + SHIFT + ALT + [1-9; 0]
for id = 1, 7 do
  local code = "code:" .. (9 + id)
  hl.bind(
    "SUPER + SHIFT + ALT + " .. code,
    hl.dsp.exec_cmd(workspace_1to7("move-silent", id)),
    { description = "Move window silently to workspace " .. id }
  )
end

-- Direct access to global workspaces 8-10
hl.bind(
  "SUPER + SHIFT + ALT + code:17",
  hl.dsp.window.move({ workspace = "8", follow = false }),
  { description = "Move window silently to workspace 8" }
)
hl.bind(
  "SUPER + SHIFT + ALT + code:18",
  hl.dsp.window.move({ workspace = "9", follow = false }),
  { description = "Move window silently to workspace 9" }
)
hl.bind(
  "SUPER + SHIFT + ALT + code:19",
  hl.dsp.window.move({ workspace = "10", follow = false }),
  { description = "Move window silently to workspace 10" }
)

-- Screenshots
hl.bind(
  "SUPER + S",
  hl.dsp.exec_cmd(HOME .. "/.local/share/bin/screenshot-window region"),
  { description = "Screenshot region" }
)
hl.bind(
  "SUPER + SHIFT + S",
  hl.dsp.exec_cmd(HOME .. "/.local/share/bin/screenshot-window window"),
  { description = "Screenshot window" }
)
hl.bind(
  "SUPER + CTRL + SHIFT + S",
  hl.dsp.exec_cmd(HOME .. "/.local/share/bin/screenshot-window fullscreen"),
  { description = "Screenshot fullscreen" }
)
hl.bind(
  "SUPER + Print",
  hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"),
  { description = "Color picker" }
)
hl.bind(
  "SUPER + SHIFT + R",
  hl.dsp.exec_cmd(HOME .. "/.local/share/bin/screenrecord-menu"),
  { description = "Screen recording menu" }
)

-- TAB between workspaces
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind("SUPER + CTRL + Tab", hl.dsp.focus({ workspace = "previous" }), { description = "Former workspace" })

-- Move active window to other monitors
hl.bind(
  "SUPER + SHIFT + ALT + Left",
  hl.dsp.window.move({ monitor = "l" }),
  { description = "Move window to left monitor" }
)
hl.bind(
  "SUPER + SHIFT + ALT + Right",
  hl.dsp.window.move({ monitor = "r" }),
  { description = "Move window to right monitor" }
)

-- Move whole workspace to other monitors
hl.bind(
  "SUPER + CTRL + SHIFT + ALT + Left",
  hl.dsp.workspace.move({ monitor = "l" }),
  { description = "Move workspace to left monitor" }
)
hl.bind(
  "SUPER + CTRL + SHIFT + ALT + Right",
  hl.dsp.workspace.move({ monitor = "r" }),
  { description = "Move workspace to right monitor" }
)

-- Swap active window with the one next to it with SUPER + SHIFT + arrow keys
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.swap({ direction = "l" }), { description = "Swap window to the left" })
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.swap({ direction = "r" }), { description = "Swap window to the right" })
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.swap({ direction = "u" }), { description = "Swap window up" })
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.swap({ direction = "d" }), { description = "Swap window down" })

-- Toggle groups
hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "Toggle window grouping" })
hl.bind(
  "SUPER + ALT + G",
  hl.dsp.window.move({ out_of_group = true }),
  { description = "Move active window out of group" }
)

-- Join groups
hl.bind(
  "SUPER + ALT + Left",
  hl.dsp.window.move({ into_group = "l" }),
  { description = "Move window to group on left" }
)
hl.bind(
  "SUPER + ALT + Right",
  hl.dsp.window.move({ into_group = "r" }),
  { description = "Move window to group on right" }
)
hl.bind(
  "SUPER + ALT + Up",
  hl.dsp.window.move({ into_group = "u" }),
  { description = "Move window to group on top" }
)
hl.bind(
  "SUPER + ALT + Down",
  hl.dsp.window.move({ into_group = "d" }),
  { description = "Move window to group on bottom" }
)

-- Navigate a single set of grouped windows
hl.bind("SUPER + ALT + Tab", hl.dsp.group.next(), { description = "Next window in group" })
hl.bind("SUPER + ALT + SHIFT + Tab", hl.dsp.group.prev(), { description = "Previous window in group" })

-- Overload lateral window navigation for grouped windows
hl.bind(
  "SUPER + ALT + Left",
  hl.dsp.group.prev(),
  { description = "Move grouped window focus left" }
)
hl.bind(
  "SUPER + ALT + Right",
  hl.dsp.group.next(),
  { description = "Move grouped window focus right" }
)

-- Scroll through a set of grouped windows with SUPER + ALT + scroll
hl.bind("SUPER + ALT + mouse_down", hl.dsp.group.next(), { description = "Next window in group" })
hl.bind("SUPER + ALT + mouse_up", hl.dsp.group.prev(), { description = "Previous window in group" })

-- Activate window in a group by number
hl.bind("SUPER + ALT + code:10", hl.dsp.group.active({ index = 1 }), { description = "Switch to group window 1" })
hl.bind("SUPER + ALT + code:11", hl.dsp.group.active({ index = 2 }), { description = "Switch to group window 2" })
hl.bind("SUPER + ALT + code:12", hl.dsp.group.active({ index = 3 }), { description = "Switch to group window 3" })
hl.bind("SUPER + ALT + code:13", hl.dsp.group.active({ index = 4 }), { description = "Switch to group window 4" })
hl.bind("SUPER + ALT + code:14", hl.dsp.group.active({ index = 5 }), { description = "Switch to group window 5" })

-- Resize active window
hl.bind(
  "SUPER + code:20",
  hl.dsp.window.resize({ x = -100, y = 0, relative = true }),
  { description = "Expand window left" }
)
hl.bind(
  "SUPER + code:21",
  hl.dsp.window.resize({ x = 100, y = 0, relative = true }),
  { description = "Shrink window left" }
)
hl.bind(
  "SUPER + SHIFT + code:20",
  hl.dsp.window.resize({ x = 0, y = -100, relative = true }),
  { description = "Shrink window up" }
)
hl.bind(
  "SUPER + SHIFT + code:21",
  hl.dsp.window.resize({ x = 0, y = 100, relative = true }),
  { description = "Expand window down" }
)

-- Toggle split direction
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Toggle window split" })

-- Move/resize windows with SUPER + LMB/RMB and dragging
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- Scroll through existing workspaces with SUPER + scroll
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll active workspace forward" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll active workspace backward" })

-- Volume and media keys
hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("swayosd-client --output-volume +5"),
  { repeating = true }
)
hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd("swayosd-client --output-volume -5"),
  { repeating = true }
)
hl.bind(
  "XF86AudioMute",
  hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),
  { description = "Toggle mute" }
)

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play"), { description = "Play media" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"), { description = "Pause media" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Toggle play/pause" })
