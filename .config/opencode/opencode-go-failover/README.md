# opencode-go-failover

OpenCode plugin that automatically switches between saved OpenCode Go accounts
when the account in use hits its usage limit.

OpenCode Go limits apply per account across 5-hour, weekly, and monthly windows.
When one account is maxed out, requests fail with a quota error even though a
second saved account may still have headroom. This plugin parks the limited
account, picks the next available one, and retries the failed request with it.

## How it works

- On setup and periodically, the plugin lists the saved accounts for the
  `opencode-go` integration and resolves each account's API key.
- The `http.request` session hook rewrites the outgoing request's auth header
  (`Authorization: Bearer …` for OpenAI-style models, `x-api-key` for
  Anthropic-style models) to the selected account.
- The `retry` session hook watches for quota failures (`provider.quota`,
  HTTP 429/402, or matching messages). It parks the failed account, selects the
  next available account, makes it the globally active account, and retries the
  request immediately.
- Parked accounts are retried after a cooldown. Each consecutive failure for
  the same account doubles the cooldown, up to a cap, so weekly or monthly
  limits are not hammered.
- The selected account is activated through the local server's credential API,
  so `/connect` and the TUI show the account actually in use. Set
  `switchGlobalAccount: false` to leave the global account alone.
- A manual `/connect` or `opencode auth switch` still wins: the plugin follows
  the active account and clears its parked state.

State is stored in the plugin's durable storage, so a service restart keeps the
current selection and parked accounts.

## Configure

Added to `~/.config/opencode/opencode.json`:

```json
{
  "plugins": ["./opencode-go-failover"]
}
```

Options can be passed with the object form:

```json
{
  "plugins": [
    {
      "package": "./opencode-go-failover",
      "options": {
        "retryDelayMs": 1000,
        "cooldownMs": 18000000,
        "debug": false
      }
    }
  ]
}
```

| Option           | Default                 | Purpose                                                                 |
| ---------------- | ----------------------- | ----------------------------------------------------------------------- |
| `integration`    | `"opencode-go"`         | Integration whose saved accounts are used for failover.                 |
| `provider`       | same as `integration`   | Provider ID whose requests are hooked.                                  |
| `retryDelayMs`   | `1000`                  | Delay before retrying a request after switching accounts.               |
| `cooldownMs`     | `18000000` (5 hours)    | Base park time for an account after a usage limit. Doubles per strike.  |
| `maxCooldownMs`  | `604800000` (7 days)    | Cap for the exponential cooldown.                                       |
| `switchOnStatus` | `[429, 402]`            | HTTP statuses treated as a usage limit.                                 |
| `switchOnTypes`  | `["provider.quota"]`    | OpenCode error types treated as a usage limit.                          |
| `patterns`       | usage-limit phrases     | Case-insensitive message patterns treated as a usage limit.             |
| `injectAuth`     | `true`                  | Set to `false` to disable auth rewriting and only retry with a switch.  |
| `switchGlobalAccount` | `true`             | Activate the selected account globally so the TUI reflects the switch.  |
| `debug`          | `false`                 | Log account selection and refresh details to the OpenCode server log.   |

## Notes

- Requests are authenticated per request, so multiple sessions can use the
  plugin at the same time. If two sessions hit a limit at once, each failed
  request parks the account it was actually using.
- When every account is parked, the plugin does not retry; the provider's
  original usage-limit error is surfaced.
- The plugin only handles saved API-key accounts. OAuth connections and
  environment-provided keys are ignored.
