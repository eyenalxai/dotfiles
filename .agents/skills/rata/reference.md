# rata command reference

## Conventions

- `<ref>` is an identifier (`ABC-42`), a UUID, or a `linear.app` URL.
- `--json` works on every command and prints one stable JSON document.
- List commands return one page: `--limit` is the page size (default 50,
  maximum 250) and `--after <cursor>` continues the list. JSON is
  `{ <plural>, pageInfo }`.
- `--body-file -` reads the value from stdin; `--body-file <path>` reads a file.
- The default team and project come from the repository config, written by
  `rata link` and removed by `rata unlink`.
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
| `rata link`                                         | Link this repository; asks for the workspace, then the team.                           |
| `rata link --team <key>`                            | Link to a team. Searches every stored workspace. `--create --name <name>` creates it.  |
| `rata link --project <name>`                        | Record the default project for this repository.                                        |
| `rata link --workspace <name>`                      | Link in one workspace profile. Skips the workspace prompt.                             |
| `rata unlink`                                       | Remove the stored link of this repository.                                             |

The API key is resolved in order: `LINEAR_API_KEY`, the repository `workspace`
from the repository config, the `default` profile. `rata link --workspace <name>`
selects that profile directly, also when `LINEAR_API_KEY` is set. With
`LINEAR_API_KEY` set, `rata link` ignores the stored profiles but keeps the
recorded `workspace`.

## Teams, projects, labels

| Command                                                                   | Description                                                                                  |
| ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `rata team list [--limit <n>] [--after <cursor>]`                         | List teams, one page per call.                                                               |
| `rata team create --name <name> [--key <key>]`                            | Create a team.                                                                               |
| `rata team delete <key> [--yes]`                                          | Delete a team (Linear keeps it recoverable). `--yes` skips the confirmation.                 |
| `rata project list [--include-archived] [--limit <n>] [--after <cursor>]` | List projects: name, state, progress, id. One page per call. Trashed rows show ` (deleted)`. |
| `rata project create --name <name> [--team <key>]`                        | Create a project. `--team` is repeatable.                                                    |
| `rata project delete <ref> [--yes]`                                       | Move a project to the trash (Linear keeps it recoverable). `--yes` skips the confirmation.   |
| `rata project restore <ref>`                                              | Bring a project back from the trash. Runs without a prompt.                                  |
| `rata label list --team <key> [--limit <n>] [--after <cursor>]`           | List the labels of a team: name, id, color. One page per call.                               |
| `rata label create --name <name> [--color <hex>] [--team <key>]`          | Create a team-scoped label. `--team` defaults to the linked team.                            |
| `rata label edit <ref> [--name <new>] [--color <hex>] [--team <key>]`     | Update a label. `<ref>` is a name or a UUID. Pass `--name`, `--color`, or both.              |

## Issues

| Command                                     | Description                                                       |
| ------------------------------------------- | ----------------------------------------------------------------- |
| `rata issue list [flags]`                   | List issues. One page per call.                                   |
| `rata search <text> [flags]`                | Full-text search. Keeps relevance ranking; paging is best effort. |
| `rata issue show <ref> [--comments]`        | Show one issue.                                                   |
| `rata issue create --title <title> [flags]` | Create an issue.                                                  |
| `rata issue update <ref> [flags]`           | Update an issue.                                                  |
| `rata issue comment <ref> --body <text>`    | Comment on an issue.                                              |
| `rata issue label add <ref> <label...>`     | Add labels.                                                       |
| `rata issue label remove <ref> <label...>`  | Remove labels.                                                    |
| `rata issue assign <assignee> <ref>`        | Assign an issue. `me` or a user id.                               |
| `rata issue unassign <ref>`                 | Clear the assignee.                                               |
| `rata issue close <ref> [--comment <text>]` | Close with an optional comment. `--comment-file -` reads stdin.   |
| `rata issue reopen <ref>`                   | Reopen.                                                           |
| `rata issue link <ref> [flags]`             | Create relations.                                                 |
| `rata issue unlink <ref> [flags]`           | Remove relations.                                                 |

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
| `--label`                  | Label name. Repeatable.                                |
| `--parent`                 | Parent issue reference.                                |
| `--state`                  | Workflow state name.                                   |
| `--assignee`               | `me`, or a user id.                                    |
| `--priority`               | `none`, `urgent`, `high`, `medium`, `low`, or `0`-`4`. |

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
