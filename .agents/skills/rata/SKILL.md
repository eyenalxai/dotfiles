---
name: rata
description: Drive Linear from the terminal with the rata CLI — read and write issues, comments, relations, and wayfinding maps. Use when a repository tracks work in Linear, when its docs/agents/issue-tracker.md names rata, or when the user asks to file, triage, comment on, link, block, claim, or close Linear issues.
---

# rata

`rata` is the Linear CLI for agent workflows. Read
`docs/agents/issue-tracker.md` for the repository's team, labels and conventions.
`reference.md` has every command, flag and JSON shape.

## Start here

```bash
command -v rata      # the binary is installed
rata status          # repo, team, states, labels, triage, cache age, docs, viewer
```

`status` works without a link. It reports the viewer, the team context and the
tracker document health. Fix a failed first command before you retry.

## Five roots

| Root     | Use                                                                             |
| -------- | ------------------------------------------------------------------------------- |
| `status` | The cached context, the viewer and the document health                          |
| `issue`  | Read the working set and write issues                                           |
| `triage` | Not available yet.                                                              |
| `map`    | Not available yet.                                                              |
| `admin`  | Setup: auth, link, unlink, workspace, config, team, project, label, doctor, api |

The setup commands live under `admin`:

- `printf '%s' "$LINEAR_API_KEY" | rata admin auth login --with-token` stores a
  key. The key resolves as `LINEAR_API_KEY`, the repository workspace, then
  `default`; `rata admin workspace use <name>` selects a profile.
- `rata admin link --team <key>` links the repository and sets the team
  timezone. A stale stored key is repaired on read with a warning; follow the
  repair hint when `status` reports it.
- `rata admin doctor` checks the known `rata` commands and removed flags in the
  tracker document.
  `--write` repairs the generated command block.
- `rata admin api --query "<graphql>"` is the read-only escape hatch. It rejects
  mutations and subscriptions and never prints the key.

The old root forms (`rata auth`, `rata whoami`, `rata config`, `rata link`,
`rata team`, ...) exit 2. `whoami` is gone; `rata status` or
`rata admin auth status` carries the viewer.

Do not guess a workflow state name. Read it from `rata status`; add `--refresh`
when `cache.ageSeconds` is stale or the context looks wrong.

## One spelling per operation

| Operation       | Canonical form                                              | Rejected form                                                                                    |
| --------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Read an issue   | `rata issue <ref>`                                          | `rata issue show <ref>`                                                                          |
| Read many       | `rata issue <ref> <ref> ...`                                | repeated `issue <ref>` calls                                                                     |
| Apply a write   | `rata issue apply <ref> --file -`                           | `issue update`, `issue label`, `issue section`, `issue assign`, `issue unassign`, `issue reopen` |
| Publish a graph | `rata issue publish --file -`                               | create then link in a loop                                                                       |
| Start           | `rata issue start <ref>`                                    | `issue assign --assignee me`                                                                     |
| Hand off        | `rata issue handoff <ref> --file -`                         |                                                                                                  |
| Close           | `rata issue close <ref> --comment-file -`                   | `issue close --comment`                                                                          |
| Add an edge     | `rata issue relate <ref> --blocked-by <ref>`                | `issue link`, `issue unlink`                                                                     |
| Comment         | `rata issue comment <ref> --body-file - --dedupe-key <key>` | `issue comment create`                                                                           |

## Write loop

```bash
rata issue create --title "<title>" --body-file - --priority <p> --assignee me
printf '%s' "$GRAPH_JSON" | rata issue publish --file -
printf '%s' "$APPLY_JSON" | rata issue apply <ref> --file -
printf '%s' "$APPLY_JSON" | rata issue apply <ref> --file - --dry-run
printf '%s' "$APPLY_JSON" | rata issue apply <ref> --file - --if-unchanged <snapshot>
rata issue start <ref>
printf '%s' "$HANDOFF_JSON" | rata issue handoff <ref> --file -
rata issue relate <ref> --blocked-by <blocker>
printf 'Started work.' | rata issue comment <ref> --body-file - --dedupe-key start-42
printf 'Done in PR #12.' | rata issue close <ref> --comment-file -
```

`issue apply` plans every action first. It touches only the fields and sections in
the document. `--dry-run` returns the plan and writes nothing.
`--if-unchanged <snapshot>` exits 4 when the issue changed. A no-op returns
`skipped`. A partial failure returns the applied actions and the failed action.

`issue publish` takes one document with `team`, `parent`, `defaults` and `nodes`.
Each node requires `key`, `kind` and `title`; `body`, `priority`, `labels`,
`assignee`, `state`, `parent` and `blockedBy` are optional. A retry reuses the
nodes and skips the edges that already exist.

`issue start` claims an unassigned issue, skips your own claim, and exits 4 with
the holder when another user holds it; `--take` reassigns. `issue handoff`
attaches the PR, applies the state and sections, and posts one deduped comment.
`issue close` refuses open children unless `--force`, closes to the first
completed state, and posts one comment; a retry is skipped.

## Errors

A failed command with JSON output writes one object to stderr and exits with the
code of its class: 2 usage or validation, 3 not found, 4 conflict, 5 auth,
6 retryable, 1 internal. A parse error writes code `usage`; help prints only for
`--help`. Read `hint` and retry once. A partial apply writes one resource
document with the applied actions, the failed action and `result.error` on
stdout, and exits with the failed action's code.

## Pointers

- Commands, flags and shapes: `reference.md`.
- Repo rules: `docs/agents/issue-tracker.md`.
- Labels: `docs/agents/triage-labels.md`.
- Install and admin: `README.md`.
