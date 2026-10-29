# rata command reference

## Conventions

- `<ref>` is an identifier (`ABC-42`), a UUID, or a `linear.app` URL.
- `--json` works on every command and prints one stable JSON document.
- List commands return one page: `--limit` is the page size (default 50,
  maximum 250) and `--after <cursor>` continues the list. JSON is
  `{ <plural>, pageInfo }`.
- `--body-file -` reads the value from stdin; `--body-file <path>` reads a file.
- The default team and project come from the repository config, written by
  `rata link` and removed by `rata unlink`. List commands default to the linked
  team; without a link they fail and ask for `--team` or `rata link`.
- Exit code 0 on success, 1 on failure. Failures print one line to stderr.

## Setup

| Command                                             | Description                                                                            |
| --------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `rata auth login --with-token [--workspace <name>]` | Read a Linear API key from stdin and save it as a profile. `default` without the flag. |
| `rata auth status [--workspace <name>]`             | Show the selected profile, viewer and organization.                                    |
| `rata auth logout [--workspace <name>]`             | Remove one profile. `default` without the flag.                                        |
| `rata workspace list`                               | List the stored profiles with their viewer and organization.                           |
| `rata workspace use <name>`                         | Set the default profile.                                                               |
| `rata whoami`                                       | Show the authenticated viewer.                                                         |
| `rata status [--json]`                              | Show the repo, workspace, key source, team, project, defaults, viewer and org.         |
| `rata link`                                         | Link this repository; asks for the workspace, then the team.                           |
| `rata link --team <key>`                            | Link to a team. Searches every stored workspace. `--create --name <name>` creates it.  |
| `rata link --project <name>`                        | Record the default project for this repository.                                        |
| `rata link --workspace <name>`                      | Link in one workspace profile. Skips the workspace prompt.                             |
| `rata config show [--json]`                         | Show the issue defaults of this repository.                                            |
| `rata config set --assignee me --label <name> ...`  | Set the issue defaults. `--label` is repeatable and replaces the list.                 |
| `rata config unset --label`                         | Clear one default. `--assignee`, `--label` and `--priority` select the fields.         |
| `rata unlink`                                       | Remove the stored link and defaults of this repository.                                |

The API key is resolved in order: `LINEAR_API_KEY`, the repository `workspace`
from the repository config, the `default` profile. `rata link --workspace <name>`
selects that profile directly, also when `LINEAR_API_KEY` is set. With
`LINEAR_API_KEY` set, `rata link` ignores the stored profiles but keeps the
recorded `workspace`.

## Teams, projects, labels

| Command                                                                                  | Description                                                                                                         |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `rata team list [--limit <n>] [--after <cursor>]`                                        | List teams, one page per call.                                                                                      |
| `rata team show [<team-ref>] [--json]`                                                   | Show the states, labels, members and priorities of a team. Defaults to the linked team.                             |
| `rata team create --name <name> [--key <key>]`                                           | Create a team.                                                                                                      |
| `rata team delete <key> [--yes]`                                                         | Delete a team (Linear keeps it recoverable). `--yes` skips the confirmation.                                        |
| `rata project list [--team <key>] [--include-archived] [--limit <n>] [--after <cursor>]` | List the projects of the linked team: name, state, progress, id. One page per call. Trashed rows show ` (deleted)`. |
| `rata project create --name <name> [--team <key>]`                                       | Create a project. `--team` is repeatable.                                                                           |
| `rata project delete <ref> [--yes]`                                                      | Move a project to the trash (Linear keeps it recoverable). `--yes` skips the confirmation.                          |
| `rata project restore <ref>`                                                             | Bring a project back from the trash. Runs without a prompt.                                                         |
| `rata label list [--team <key>] [--limit <n>] [--after <cursor>]`                        | List the labels of the linked team: name, id, color. One page per call.                                             |
| `rata label create --name <name> [--color <hex>] [--team <key>] [--if-not-exists]`       | Create a team-scoped label. `--team` defaults to the linked team. `--if-not-exists` returns the existing label.     |
| `rata label edit <ref> [--name <new>] [--color <hex>] [--team <key>]`                    | Update a label. `<ref>` is a name or a UUID. Pass `--name`, `--color`, or both.                                     |

## Issues

| Command                                              | Description                                                        |
| ---------------------------------------------------- | ------------------------------------------------------------------ |
| `rata issue list [flags]`                            | List issues. One page per call.                                    |
| `rata search <text> [flags]`                         | Full-text search. Keeps relevance ranking; paging is best effort.  |
| `rata issue show <ref> [--comments] [--no-comments]` | Show one issue with comments, children, relations and attachments. |
| `rata issue create --title <title> [flags]`          | Create an issue.                                                   |
| `rata issue update <ref> [flags]`                    | Update an issue.                                                   |
| `rata issue comment <ref> --body <text>`             | Comment on an issue.                                               |
| `rata issue label add <ref> <label...>`              | Add labels.                                                        |
| `rata issue label remove <ref> <label...>`           | Remove labels.                                                     |
| `rata issue assign <ref> --assignee <value>`         | Assign an issue. `me`, a user id, or `none` to clear it.           |
| `rata issue unassign <ref>`                          | Clear the assignee.                                                |
| `rata issue close <ref> [--comment <text>]`          | Close with an optional comment. `--comment-file -` reads stdin.    |
| `rata issue reopen <ref>`                            | Reopen.                                                            |
| `rata issue link <ref> [flags]`                      | Create relations.                                                  |
| `rata issue unlink <ref> [flags]`                    | Remove relations.                                                  |

### `issue list` flags

| Flag           | Meaning                                                                  |
| -------------- | ------------------------------------------------------------------------ |
| `--team`       | Team key or id.                                                          |
| `--state`      | Workflow state name, for example `In Progress`.                          |
| `--state-type` | `triage`, `backlog`, `unstarted`, `started`, `completed`, or `canceled`. |
| `--priority`   | `none`, `urgent`, `high`, `medium`, `low`, or `0`-`4`.                   |
| `--label`      | Label name.                                                              |
| `--assignee`   | `me`, or a user id.                                                      |
| `--project`    | Project id or name.                                                      |
| `--parent`     | Parent issue reference.                                                  |
| `--text`       | Text in the title or the description.                                    |
| `--unblocked`  | Only open issues with no open blocker.                                   |
| `--unassigned` | Only issues with no assignee.                                            |
| `--sort`       | `priority`: urgent first and none last; ties keep the incoming order.    |
| `--limit`      | Page size. Default: 50, maximum: 250.                                    |
| `--after`      | Continue after a cursor from a previous page.                            |

### `search` flags

| Flag      | Meaning                                           |
| --------- | ------------------------------------------------- |
| `--team`  | Team key or id. Default: the linked team.         |
| `--limit` | Page size. Default: 50, maximum: 250.             |
| `--after` | Continue after a cursor from a previous page.     |
| `--json`  | Print `{ "issues": [...], "pageInfo": { ... } }`. |

Search keeps Linear's relevance ranking, so its paging is best effort. Keep the
search text fixed across pages.

### List JSON

Every list command prints one page:

```json
{
  "issues": [],
  "pageInfo": { "hasNextPage": true, "endCursor": "b2c3..." }
}
```

The plural key matches the command: `issues`, `teams`, `projects`, or `labels`.
`pageInfo.hasNextPage` says whether a next page exists. Pass
`pageInfo.endCursor` to `--after` to read it. Keep the filters and the order
fixed across pages: a cursor is bound to its query. Lists are ordered by
creation time.

The priority sort fetches every matching issue across all pages before
`--limit` applies. With `--unblocked`, blocked issues are dropped first.

### `issue create` flags

| Flag                       | Meaning                                                |
| -------------------------- | ------------------------------------------------------ |
| `--title`                  | Required.                                              |
| `--body` / `--body-file -` | Description.                                           |
| `--team`                   | Team key or id. Default: the repository config.        |
| `--project`                | Project. Default: the repository config.               |
| `--label`                  | Label name. Repeatable. Adds to the default labels.    |
| `--no-default-labels`      | Drop the default labels for this call.                 |
| `--parent`                 | Parent issue reference.                                |
| `--state`                  | Workflow state name.                                   |
| `--assignee`               | `me`, a user id, or `none` to skip the default.        |
| `--priority`               | `none`, `urgent`, `high`, `medium`, `low`, or `0`-`4`. |
| `--dry-run`                | Print the planned create without writing.              |

### `issue update` flags

`--title`, `--body` / `--body-file -`, `--state`, `--assignee`, `--project`,
`--parent`, `--priority`. The priority values are the same as `issue create`,
and `none` clears the priority.

### `issue link` and `issue unlink` flags

| Flag           | Meaning                                          |
| -------------- | ------------------------------------------------ |
| `--blocks`     | The other issue waits for this one. Repeatable.  |
| `--blocked-by` | This issue waits for the other one. Repeatable.  |
| `--related`    | Related, with no direction. Repeatable.          |
| `--duplicate`  | This issue duplicates the other one. Repeatable. |

### Writes

`issue create`, `issue link`, `issue unlink`, `issue assign`, `issue unassign`,
`issue label add`, `issue label remove`, `config set` and `config unset` accept
`--dry-run`. It resolves the targets and prints the actions; no mutation runs.
JSON is `{ "dryRun": true, "actions": [...] }`.

These writes are idempotent: a repeat exits 0 and reports `skipped` in JSON.
`unlink` with a missing relation is a skipped success. `label create` fails on a
duplicate name with `conflict` unless `--if-not-exists` returns the existing
label with `created: false`.
