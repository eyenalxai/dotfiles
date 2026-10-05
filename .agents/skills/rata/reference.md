# rata command reference

## Conventions

- `<ref>` is an identifier (`PER-42`), a UUID, or a `linear.app` URL.
- `--json` works on every command and prints one stable JSON document.
- `--body-file -` reads the value from stdin; `--body-file <path>` reads a file.
- The default team and project come from `.rata.json`, written by `rata init`.
- Exit code 0 on success, 1 on failure. Failures print one line to stderr.

## Setup

| Command                        | Description                                                                               |
| ------------------------------ | ----------------------------------------------------------------------------------------- |
| `rata auth login --with-token` | Read a Linear API key from stdin and save it.                                             |
| `rata auth status`             | Show the authenticated viewer and the key source.                                         |
| `rata auth logout`             | Remove the saved key.                                                                     |
| `rata whoami`                  | Show the authenticated viewer.                                                            |
| `rata init --team <key>`       | Write `.rata.json`, install `docs/agents/issue-tracker.md`, update the `AGENTS.md` block. |
| `rata init --print`            | Print the tracker document. Write nothing.                                                |
| `rata init --force`            | Overwrite existing files.                                                                 |
| `rata init --ensure-labels`    | Create the canonical labels in the team.                                                  |

`LINEAR_API_KEY` takes precedence over the saved key.

## Teams, projects, labels

| Command                          | Description                                       |
| -------------------------------- | ------------------------------------------------- |
| `rata team list`                 | List teams.                                       |
| `rata project list`              | List projects.                                    |
| `rata label list --team <key>`   | List the labels of a team.                        |
| `rata label ensure --team <key>` | Create the canonical labels that the team misses. |

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
| `--unblocked`  | Exclude issues with an open blocker.                                     |
| `--unassigned` | Exclude issues with an assignee.                                         |
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
