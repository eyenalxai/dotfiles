# rata command reference

## Conventions

- `<ref>` is an identifier (`ABC-42`), a UUID, or a `linear.app` URL.
- `--json` works on every command and prints one stable JSON document.
- `--body-file -` reads the value from stdin; `--body-file <path>` reads a file.
- The default team and project come from `.rata.json`, written by `rata link`.
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

The API key is resolved in order: `LINEAR_API_KEY`, the repository `workspace`
from `.rata.json`, the `default` profile. `rata link --workspace <name>` selects
that profile directly, also when `LINEAR_API_KEY` is set. With `LINEAR_API_KEY`
set, `rata link` ignores the stored profiles but keeps the recorded `workspace`.

## Teams, projects, labels

| Command                                            | Description                                                                  |
| -------------------------------------------------- | ---------------------------------------------------------------------------- |
| `rata team list`                                   | List teams.                                                                  |
| `rata team create --name <name> [--key <key>]`     | Create a team.                                                               |
| `rata team delete <key> [--yes]`                   | Delete a team (Linear keeps it recoverable). `--yes` skips the confirmation. |
| `rata project list`                                | List projects: name, state, progress, id.                                    |
| `rata project create --name <name> [--team <key>]` | Create a project. `--team` is repeatable.                                    |
| `rata label list --team <key>`                     | List the labels of a team.                                                   |

## Issues

| Command                                     | Description                                                     |
| ------------------------------------------- | --------------------------------------------------------------- |
| `rata issue list [flags]`                   | List issues.                                                    |
| `rata search <text>`                        | Full-text search.                                               |
| `rata issue show <ref> [--comments]`        | Show one issue.                                                 |
| `rata issue create --title <title> [flags]` | Create an issue.                                                |
| `rata issue update <ref> [flags]`           | Update an issue.                                                |
| `rata issue comment <ref> --body <text>`    | Comment on an issue.                                            |
| `rata issue label add <ref> <label...>`     | Add labels.                                                     |
| `rata issue label remove <ref> <label...>`  | Remove labels.                                                  |
| `rata issue assign <assignee> <ref>`        | Assign an issue. `me` or a user id.                             |
| `rata issue unassign <ref>`                 | Clear the assignee.                                             |
| `rata issue close <ref> [--comment <text>]` | Close with an optional comment. `--comment-file -` reads stdin. |
| `rata issue reopen <ref>`                   | Reopen.                                                         |
| `rata issue link <ref> [flags]`             | Create relations.                                               |
| `rata issue unlink <ref> [flags]`           | Remove relations.                                               |

### `issue list` flags

| Flag           | Meaning                                                                  |
| -------------- | ------------------------------------------------------------------------ |
| `--team`       | Team key or id.                                                          |
| `--state`      | Workflow state name, for example `In Progress`.                          |
| `--state-type` | `triage`, `backlog`, `unstarted`, `started`, `completed`, or `canceled`. |
| `--label`      | Label name.                                                              |
| `--assignee`   | `me`, or a user id.                                                      |
| `--project`    | Project id or name.                                                      |
| `--parent`     | Parent issue reference.                                                  |
| `--text`       | Text in the title or the description.                                    |
| `--unblocked`  | Only open issues with no open blocker.                                   |
| `--unassigned` | Only issues with no assignee.                                            |
| `--limit`      | Maximum number of issues. Default: 50.                                   |

### `issue create` flags

| Flag                       | Meaning                                                |
| -------------------------- | ------------------------------------------------------ |
| `--title`                  | Required.                                              |
| `--body` / `--body-file -` | Description.                                           |
| `--team`                   | Team key or id. Default: `.rata.json`.                 |
| `--project`                | Project. Default: `.rata.json`.                        |
| `--label`                  | Label name. Repeatable.                                |
| `--parent`                 | Parent issue reference.                                |
| `--state`                  | Workflow state name.                                   |
| `--assignee`               | `me`, or a user id.                                    |
| `--priority`               | `none`, `urgent`, `high`, `medium`, `low`, or `0`-`4`. |

### `issue update` flags

`--title`, `--body` / `--body-file -`, `--state`, `--assignee`, `--project`,
`--parent`.

### `issue link` and `issue unlink` flags

| Flag           | Meaning                                          |
| -------------- | ------------------------------------------------ |
| `--blocks`     | The other issue waits for this one. Repeatable.  |
| `--blocked-by` | This issue waits for the other one. Repeatable.  |
| `--related`    | Related, with no direction. Repeatable.          |
| `--duplicate`  | This issue duplicates the other one. Repeatable. |
