--[[
  Window rules and dynamic window configuration.

  Equivalent to the old windows.conf.
--]]

hl.config({
  misc = {
    focus_on_activate = false,
  },
})

-- Global opacity setting
hl.window_rule({
  name = "global-opacity",
  match = { class = ".*" },
  opacity = "1 1",
})

-- kopa clipboard manager
hl.window_rule({
  name = "kopa-float",
  match = { class = "com.kopa.kopa" },
  float = true,
  size = { 800, 652 },
})

-- Place apps on specific workspaces
hl.window_rule({
  name = "telegram-workspace",
  match = { class = "^(org.telegram.desktop)$" },
  workspace = "9",
})

hl.window_rule({
  name = "happ-workspace",
  match = { class = "^([Hh]app)$" },
  workspace = "12",
})

hl.window_rule({
  name = "steam-workspace",
  match = { class = "^(steam)$" },
  workspace = "13",
})

-- Hide the extra Cheat Engine window (white square)
hl.window_rule({
  name = "cheatengine-hide",
  match = {
    class = "^(steam_proton)$",
    title = "^(Cheat Engine)$",
  },
  opacity = "0 0",
  size = { 1, 1 },
  move = { -10000, -10000 },
})

hl.window_rule({
  name = "steam-friends-float",
  match = {
    class = "^(steam)$",
    title = "^(Friends List)$",
  },
  float = true,
})

-- Factorio
hl.window_rule({
  name = "factorio-fullscreen",
  match = { class = "^(factorio)$" },
  workspace = "7",
  fullscreen = true,
})

-- Tag Chromium-browser as chromium-based-browser (fixes Puppeteer launched browsers)
hl.window_rule({
  name = "chromium-tag",
  match = { class = "Chromium-browser" },
  tag = "+chromium-based-browser",
})

-- Strudel REPL - force tiling (disable floating)
hl.window_rule({
  name = "strudel-repl-tile",
  match = { title = "^(Strudel REPL)$" },
  tile = true,
})

hl.window_rule({
  name = "strudel-chromium-tile",
  match = {
    class = "^(Chromium-browser)$",
    title = "^(strudel.cc)$",
  },
  tile = true,
})

hl.window_rule({
  name = "strudel-initial-tile",
  match = { initial_title = "^(strudel.cc)$" },
  tile = true,
})

-- Floating windows with specific tag
hl.window_rule({
  name = "floating-window-float",
  match = { tag = "floating-window" },
  float = true,
  center = true,
  size = { 875, 600 },
})

-- System TUIs (btop, Wi-Fi, Bluetooth)
hl.window_rule({
  name = "btop-floating",
  match = { class = "^(sys\\.btop)$" },
  float = true,
  center = true,
  size = { 1200, 800 },
})

hl.window_rule({
  name = "impala-floating",
  match = { class = "^(sys\\.impala)$" },
  tag = "+floating-window",
})

hl.window_rule({
  name = "nmtui-floating",
  match = { class = "^(sys\\.nmtui)$" },
  tag = "+floating-window",
})

hl.window_rule({
  name = "bluetui-floating",
  match = { class = "^(sys\\.bluetui)$" },
  tag = "+floating-window",
})

-- 1Password
hl.window_rule({
  name = "1password-noscreenshare",
  match = { class = "^(1[p|P]assword)$" },
  no_screen_share = true,
  tag = "+floating-window",
})
