# max-context

OpenCode plugin that caps model context windows so automatic compaction runs
at a smaller budget than the provider's native window.

## How it works

OpenCode starts automatic compaction when the estimated conversation size
reaches the selected model's context limit, minus room for the model's output
and the configured compaction buffer. The plugin lowers `model.limit.context`
(and `model.limit.input` when present) through a catalog transform, so those
limits drive compaction. No compaction behavior is reimplemented here.

Models whose catalog window is unknown (`0`) adopt the configured cap, because
OpenCode otherwise never auto-compacts them. Some catalog snapshots, such as
`openrouter/anthropic/*`, report an unknown window.

## Configure

Plugins are loaded from `~/.config/opencode/opencode.json`:

```json
{
  "plugins": [
    {
      "package": "./max-context",
      "options": {
        "maxContext": 100000,
        "models": {
          "openrouter/anthropic/*": 200000,
          "openrouter/openai/gpt-5.2": false
        }
      }
    }
  ]
}
```

- `maxContext` — cap applied to every model. A number of tokens, or `false` to
  leave models uncapped.
- `models` — per-model overrides keyed by `providerID/modelID`. `*` matches any
  run of characters. More specific patterns win; ties go to the later entry, so
  `models` beats `maxContext`. `false` opts a model out of every cap.

Only positive integers are accepted; invalid values are ignored with a warning.
OpenCode reloads the plugin when this file changes.
