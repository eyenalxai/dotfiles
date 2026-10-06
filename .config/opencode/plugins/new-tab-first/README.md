# new-tab-first

Keeps **brand-new tabs at the top of the vertical session rail**. When you
start a new thread it appears first, instead of being appended at the bottom.

## Rules

- Active only when vertical tabs are shown: `tabs.layout` is `"vertical"` in
  `cli.json` **and** the terminal is wide enough for the rail, using the same
  fit check the TUI applies (`width >= railWidth + 64`). In the horizontal
  strip, or on a narrow terminal, the plugin does nothing.
- Only tabs that appear while the plugin is running are moved. The tabs that
  are already open keep their order, including after a plugin reload.
- Each new tab moves exactly once, at the moment it appears. Nothing re-sorts
  later, so the strip never churns.
- A session that was closed and is reopened later is not treated as new.
- Moves go through the same API as dragging a tab, so the order persists.

Not covered: the `+ New session` button is rendered by the TUI itself, after
the tab list inside the rail, so a plugin cannot move it above the list. That
would be an upstream change to OpenCode.

## How it works

- `new-tabs.ts` — pure snapshot bookkeeping: seed on the first non-empty tab
  list, report unseen IDs, emit one `move(id, 0)` per appearance.
- `config.ts` — reads `cli.json` (`OPENCODE_CONFIG_DIR` /
  `XDG_CONFIG_HOME` / `~/.config`) and the persisted rail width
  (`$XDG_STATE_HOME/opencode/<channel>/tui/layout.json`), and mirrors the
  TUI's `sessionTabsFitVertically` / `clampSessionTabsWidth` rules.
- `tui.ts` — the plugin: mounts one effect in the `app` slot, watches
  `context.ui.tabs.list()`, and calls `context.ui.tabs.move` only when a new
  tab appears while vertical tabs are active.

## Options

- `debug` — log appearances and decisions (default `false`). Configure via
  `cli.json`:

```jsonc
{
  "plugins": [
    { "package": "./plugins/new-tab-first", "options": { "debug": true } }
  ]
}
```

The plugin is auto-discovered from `<config>/plugins`, so no `cli.json` entry
is required for the default behavior.

## Tests

Offline only — a mocked TUI, mocked `solid-js`, and real config files in temp
directories. No OpenCode process involved:

```
bun test
```

## Removing it

Delete this directory (`~/.config/opencode/plugins/new-tab-first`); the TUI
unloads it on the next file event.
