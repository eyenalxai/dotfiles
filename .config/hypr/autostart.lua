--[[
  Autostart processes.

  Equivalent to the old autostart.conf.
--]]

local HOME = os.getenv("HOME") or ""

hl.on("hyprland.start", function()
  -- Extra autostart processes
  hl.exec_cmd("uwsm app -- 1password")

  -- For keyring to work
  -- NOTE: original config had a typo here ("uwm" instead of "uwsm"); preserved exactly.
  hl.exec_cmd("uwm app -- dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("uwsm app -- gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg")

  -- Polkit authentication agent for system auth prompts
  hl.exec_cmd("uwsm app -- /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

  -- Walker
  hl.exec_cmd("uwsm app -- walker --gapplication-service")

  -- Elephant search service
  hl.exec_cmd("uwsm app -- elephant")

  -- Wallpaper
  hl.exec_cmd("uwsm app -- swaybg -i " .. HOME .. "/.config/theme/current/background -m fill")

  -- SwayOSD
  hl.exec_cmd("uwsm app -- swayosd-server")
end)
