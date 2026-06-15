--[[
  Theme color loader.

  Reads the current theme's colors.toml and any $VAR overrides from
  ~/.config/theme/current/theme/hyprland.conf, then exposes them as Lua values
  the config can pass to hl.config().

  Because this is evaluated on every config reload, switching themes with
  `theme-set` (which runs `hyprctl reload`) will pick up the new palette
  automatically.
--]]

local M = {}

local HOME = os.getenv("HOME") or ""
local THEME_DIR = HOME .. "/.config/theme/current/theme"

local function read_lines(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end

  local lines = {}
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  return lines
end

local function parse_colors_toml(path)
  local colors = {}
  for _, line in ipairs(read_lines(path) or {}) do
    local key, value = line:match('^%s*([%w_]+)%s*=%s*"(.-)"%s*$')
    if key and value then
      colors[key] = value
    end
  end
  return colors
end

local function parse_hyprland_vars(path)
  local vars = {}
  for _, line in ipairs(read_lines(path) or {}) do
    local key, value = line:match("^%s*%$(%w+)%s*=%s*(.-)%s*$")
    if key and value then
      vars[key] = value
    end
  end
  return vars
end

local function hex_to_rgba(hex, alpha)
  hex = hex:gsub("^#", "")
  return "rgba(" .. hex .. alpha .. ")"
end

function M.load()
  local colors = parse_colors_toml(THEME_DIR .. "/colors.toml")
  local vars = parse_hyprland_vars(THEME_DIR .. "/hyprland.conf")

  return {
    -- Border colors (honour $activeBorderColor/$inactiveBorderColor if present)
    active = vars.activeBorderColor or colors.accent or "rgb(7daea3)",
    inactive = vars.inactiveBorderColor or colors.color0 or "rgb(3c3836)",

    -- Base palette
    foreground = colors.foreground or "rgb(d4be98)",
    background = colors.background or "rgb(282828)",
    color0 = colors.color0 or "rgb(3c3836)",

    -- Derived groupbar colours
    foreground_inactive = hex_to_rgba(
      colors.foreground or "#d4be98",
      "90"
    ),
  }
end

return M
