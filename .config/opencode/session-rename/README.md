# session-rename

An OpenCode V2 server plugin that adds a `/rename` slash command. It retitles
the current session from its own conversation — nothing is added to the
transcript.

## Usage

| Input | Effect |
| --- | --- |
| `/rename` | Generates a title from the conversation and applies it to the current session. |
| `/rename Fix flaky auth tests` | Applies the text as the title, skipping generation. |

The generated title uses the session's current model unless a `model` option is
configured. Generation runs as a transient request, so it never appears in the
conversation history and never invokes tools.

## Configuration

Loaded globally from `~/.config/opencode/opencode.json`:

```jsonc
{
  "plugins": [
    {
      "package": "./session-rename",
      "options": {
        "model": "opencode-go/deepseek-v4.1-flash", // optional override
        "maxChars": 60,
        "maxMessages": 24,
        "maxTranscriptChars": 8000,
      },
    },
  ],
}
```

| Option | Default | Meaning |
| --- | --- | --- |
| `model` | session model | `providerID/modelID` or `providerID/modelID#variant` used for generation. |
| `maxChars` | `60` | Maximum title length. Longer results are cut at a word boundary. |
| `maxMessages` | `24` | Recent messages fed to the title model (plus the opening message). |
| `maxTranscriptChars` | `8000` | Transcript character budget. |

## Notes

- The plugin is a server plugin, not a TUI plugin, so it lives in
  `opencode.json`, not `cli.json`.
- Failures are logged to the server log
  (`~/.local/share/opencode/log/opencode.log`, filter `role=server`) and
  surface as a command error.
