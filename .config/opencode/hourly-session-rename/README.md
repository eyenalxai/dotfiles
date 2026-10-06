# hourly-session-rename

OpenCode plugin that refreshes session titles as conversations evolve. Every
hour it finds the sessions in its location that have new activity since it last
titled them, generates a title, and writes it back. It also adds a `/rename`
command that renames the current session on demand.

## Uses OpenCode's built-in title generator

Titles are generated with OpenCode's own title generator prompt — the same
prompt the built-in automatic titling and the `/rename` action use — so the
result matches what OpenCode would produce itself.

A note on the built-in `/rename`: it is a TUI dialog (bound to `ctrl+r`) that
only calls `session.update({ title })`. There is no server endpoint that
regenerates a title, so a plugin cannot invoke it directly. This plugin reuses
the built-in prompt instead and registers its own `/rename` command that skips
the dialog:

- `/rename` — generate a title for the current session automatically.
- `/rename some words` — set the title to `some words` verbatim.

Set `command: false` to disable the command.

## How it works

- Each loaded location gets its own plugin instance. An instance only considers
  sessions whose `location.directory` matches its own `ctx.location.directory`,
  so several open projects never re-title the same session twice.
- On each run the plugin lists the location's sessions through the local server
  API (`GET /api/session?directory=…`) and keeps the ones updated within
  `activeWindowMs` whose `time.updated` is newer than the last time the plugin
  titled them.
- For each candidate it builds a short excerpt from the session context (first
  message plus the most recent messages), generates a title with
  `ctx.generate.text` using the built-in prompt, cleans up the reply, and saves
  it with `ctx.session.update`.
- The title write bumps the session's `time.updated`, and the plugin records a
  timestamp after the write, so an unchanged session is skipped on later runs
  until new activity arrives.
- Per-session bookkeeping lives in plugin storage and is pruned after
  `stateTtlMs`.

Sessions with fewer than `minMessages` text messages are left alone until they
have enough conversation to title.

## Why the HTTP API for listing

The plugin context exposes a curated subset of the session client (`create`,
`get`, `update`, `context`, …) but no `session.list`, so there is no supported
way to enumerate sessions from `ctx`. The plugin reads the local service
registry — the same `service.json` the `opencode-go-failover` plugin uses — and
calls `GET /api/session`, which supports filtering by directory. Renames still
go through `ctx.session.update`.

## Configure

Added to `~/.config/opencode/opencode.json`:

```json
{
  "plugins": ["./hourly-session-rename"]
}
```

Options can be passed with the object form:

```json
{
  "plugins": [
    {
      "package": "./hourly-session-rename",
      "options": {
        "intervalMs": 3600000,
        "maxPerRun": 5
      }
    }
  ]
}
```

| Option               | Default             | Purpose                                                                                     |
| -------------------- | ------------------- | ------------------------------------------------------------------------------------------- |
| `intervalMs`         | `3600000` (1 hour)  | How often to check for sessions to re-title. Clamped to at least 10 seconds.                |
| `jitterMs`           | `300000` (5 min)    | Random extra delay added to each run, so multiple locations do not fire at once.            |
| `startDelayMs`       | `60000` (1 min)     | Delay before the first run when `runOnStart` is set.                                        |
| `runOnStart`         | `true`              | Run once shortly after the plugin loads, instead of waiting a full interval.                |
| `activeWindowMs`     | `86400000` (24 h)   | Only sessions updated within this window are considered active.                             |
| `maxPerRun`          | `5`                 | Maximum sessions re-titled per run, to bound model cost.                                    |
| `scanLimit`          | `100`               | Sessions fetched from the API per run (most recent first).                                  |
| `minMessages`        | `2`                 | Minimum text messages before a session can be titled.                                       |
| `maxTitleChars`      | `50`                | Maximum title length (matches the built-in generator).                                      |
| `maxTranscriptChars` | `4000`              | Maximum characters of conversation sent to the model.                                       |
| `stateTtlMs`         | `604800000` (7 d)   | How long to keep per-session bookkeeping.                                                   |
| `includeChildren`    | `false`             | Also title child sessions (subagents), which are skipped by default.                        |
| `includeArchived`    | `false`             | Also title archived sessions.                                                               |
| `scope`              | `"location"`        | `"location"` limits each instance to its own directory; `"all"` processes every session (may duplicate work across loaded locations). |
| `model`              | session's model     | `{ "providerID": "…", "id": "…" }` used for title generation. Defaults to the session's model, then the global default model. |
| `instructions`       | built-in prompt     | System instruction used when asking the model for a title. Defaults to OpenCode's built-in title generator prompt. |
| `command`            | `"rename"`          | Name of the on-demand rename command, or `false` to disable it.                            |
| `commandDescription` | built-in            | Description shown for the rename command.                                                   |
| `dryRun`             | `false`             | Log the titles it would write without changing anything.                                    |
| `debug`              | `false`             | Log skipped sessions and failures to the OpenCode server log.                               |

## Notes

- Titles are generated with a one-shot `ctx.generate.text` call, so the
  generation does not touch the session's history or agent.
- A title is only written when the generated title differs from the current one,
  and the plugin records the revision it titled either way, so it does not
  repeatedly call the model for unchanged sessions.
- Set `dryRun: true` (and `debug: true`) to preview behavior before enabling
  real renames.
