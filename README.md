# Intro

Personal dotfiles for a Wayland-based Linux desktop.

## Components

- **Shell and prompt**: `zsh`, Oh My Zsh, Starship, FZF, zoxide, language toolchains (Node via `n`, Go, Cargo), and local scripts on `PATH`.
- **Editor and terminal**: Neovim with LazyVim (`.config/nvim`), Ghostty terminal config, plus helpers for REPL/tools.
- **Window manager**: Hyprland with split configs for monitors, input, keybindings, window rules, autostart, and appearance.
- **Bars and notifications**: Waybar status bar and Mako notifications configured for Hyprland workspaces, audio, network, Bluetooth, CPU, memory, clock, and screen recording.
- **Launcher and search**: Walker application launcher, Elephant search service, and Clipse clipboard manager.
- **Theming**: Catppuccin-based themes (Mocha/Latte) wired into Hyprland, Waybar, Mako, Ghostty, btop, VS Code, and Walker via `.config/theme/*` and `current`.
- **Apps and services**: 1Password, Telegram, AmneziaVPN, swaybg wallpaper, screen capture tools (`grim`, `slurp`), system TUIs (btop, Wi‑Fi, Bluetooth, nmtui/impala), and UW SM-based app launching.
- **Git and dotfile management**: Git config, yadm settings, and small helper scripts under `.local/share/bin` (Wi‑Fi, Bluetooth, screen recording, theme menu, TUI focus).
