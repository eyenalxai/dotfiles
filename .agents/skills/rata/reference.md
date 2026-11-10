# rata command reference

## Conventions

- `<ref>` is an identifier (`ABC-42`), a UUID, or a `linear.app` URL.
- `--json` is a global flag: it works before or after the subcommand and prints
  one stable JSON document. A read of one resource prints the resource object. A
  list prints `{ <plural>, pageInfo }`. A context document keeps its named
  sections. A write prints its result object.
- `--fields` selects dotted paths from the supported read commands and needs
  `--json`. The paths start at the resource for a read and at each row for a
  list. Write commands reject the flag.
- List commands return one page: `--limit` is the page size (default 50,
  maximum 250) and `--after <cursor>` continues the list. Add `--all` to drain
  every page.
- `--body-file -` reads the value from stdin; `--body-file <path>` reads a file.
- The default team and project come from the repository config, written by
  `rata link` and removed by `rata unlink`. List commands default to the linked
  team; without a link they fail and ask for `--team` or `rata link`.
- Exit code 0 on success; a failure exits with the code of its class, from 1 to 6. With `--json`, a failure writes one JSON object to stderr. A bulk write
  reports its results on stdout and exits with the first failed result's code.
  `issue update --comment` writes its partial result only to stdout when the
  comment fails.

## One way per operation

Each operation has one canonical form. The other spellings fail with one
`validation` hint that names it.

| Operation           | Canonical form                                               | Rejected form                |
| ------------------- | ------------------------------------------------------------ | ---------------------------- |
| Read one issue      | `rata issue show <ref>`                                      | `rata issue <ref>`           |
| Read the summary    | `rata issue show <ref> --summary`                            |                              |
| Read the status     | `rata issue status <ref>`                                    |                              |
| List issues         | `rata issue list <filters>`                                  |                              |
| Comment on an issue | `rata issue comment create <ref> --body-file -`              | `rata issue comment <ref>`   |
| Assign an issue     | `rata issue assign <ref> --assignee <me\|none\|id>`          | `rata issue assign <ref> me` |
| Assign every child  | `rata issue assign --parent <ref> --assignee <me\|none\|id>` |                              |
| Change an issue     | `rata issue update <ref> <flags>`                            |                              |
| Edit one section    | `rata issue section replace <ref> "<heading>" --body-file -` |                              |

`issue view` is the only alias, and it means `issue show`. There is no positional
assignee, no direct `issue comment <ref>` form, and no bare `issue <ref>`
execution. A rejected form exits 2 and writes no data.

## Global flags and errors

```bash
rata --json issue list
rata issue list --json --fields identifier,title,state.name
```

With `--json`, a failure writes one object to stderr and exits with the code of
its class. Two cases write only to stdout instead: a bulk write reports one
result per issue and exits with the first failed result's code, and a failed
`issue update --comment` reports the issue update, `"comment": null` and the
`error` object and exits with the error's code.

```json
{
  "error": {
    "code": "conflict",
    "message": "The label `Bug` already exists.",
    "hint": "Labels resolve case-insensitively; use `Bug`, or pass `--if-not-exists`."
  }
}
```

`hint` is a string or `null`; `RATA_DEBUG=1` adds `details`. The codes are
`validation`, `not_linked`, `not_found`, `ambiguous`, `auth`, `forbidden`,
`conflict`, `rate_limited`, `network` and `internal`. In human mode the error
prints `error: <message>` and, when present, `hint: <hint>` on stderr.

`--fields` applies to the command's own resource: the issue object of
`issue show`, `issue status`, `next` or `why`, the team object of `team show`,
the section object of `issue section get`, each item of `issues`, `teams`,
`labels` or `projects`, the `defaults` object of `config show`, or the whole
`status` document. A list result keeps its `pageInfo`. A path through a null
object returns `null`; for example `assignee.name` on an unassigned issue gives
`{"assignee": null}`. An array is selectable as a whole, such as `labels`, but a
path into an array is `validation` with a hint that names the array. An unknown
path is `validation` and the hint lists the valid keys at the failing level.

`--fields` is valid on `status`, `issue show`, `issue status`, `next`, `why`,
`issue section get`, `issue list`, `search`, `team show`, `team list`,
`label list`, `project list` and `config show`. Other commands reject it with
`validation`.

`NO_COLOR=1` drops color from help and errors. Rata's own output is plain text.

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

`status` exits 0 when the stored team key is stale. `team` and `defaults` become
`null`, and `warning` names the key and the repair: run `rata team list`, then
`rata link --team <key>`. Human output prints the warning on stderr.

On first use, rata imports a legacy `.rata.json` into the database and removes
the file. A failed remove prints a warning on stderr and the command proceeds. A
missing file is success.

## Teams, projects, labels

| Command                                                                                          | Description                                                                                                                                    |
| ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `rata team list [--limit <n>] [--after <cursor>] [--all]`                                        | List the teams in the workspace. One page per call; `--all` drains every page.                                                                 |
| `rata team show [<team-ref>] [--json]`                                                           | Show the states, labels, members and priorities of a team. Defaults to the linked team.                                                        |
| `rata team create --name <name> [--key <key>]`                                                   | Create a team.                                                                                                                                 |
| `rata team delete <key> [--yes]`                                                                 | Delete a team (Linear keeps it recoverable). `--yes` skips the confirmation.                                                                   |
| `rata project list [--team <key>] [--include-archived] [--limit <n>] [--after <cursor>] [--all]` | List the projects of the linked team: name, state, progress, id. One page per call; `--all` drains every page. Trashed rows show ` (deleted)`. |
| `rata project create --name <name> [--team <key>]`                                               | Create a project. `--team` is repeatable.                                                                                                      |
| `rata project delete <ref> [--yes]`                                                              | Move a project to the trash (Linear keeps it recoverable). `--yes` skips the confirmation.                                                     |
| `rata project restore <ref>`                                                                     | Bring a project back from the trash. Runs without a prompt.                                                                                    |
| `rata label list [--team <key>] [--limit <n>] [--after <cursor>] [--all]`                        | List the labels of the linked team: name, id, color. One page per call; `--all` drains every page.                                             |
| `rata label create --name <name> [--color <hex>] [--team <key>] [--if-not-exists]`               | Create a team-scoped label. `--team` defaults to the linked team. `--if-not-exists` returns the existing label.                                |
| `rata label edit <ref> [--name <new>] [--color <hex>] [--team <key>]`                            | Update a label. `<ref>` is a name or a UUID. Pass `--name`, `--color`, or both.                                                                |

## Issues

| Command                                               | Description                                                                    |
| ----------------------------------------------------- | ------------------------------------------------------------------------------ |
| `rata issue list [flags]`                             | List issues. One page per call. `--include relations` adds the blocking edges. |
| `rata next --parent <ref>`                            | Show the next ready child: priority, then oldest `createdAt`.                  |
| `rata why <ref>`                                      | Show one level of the blocking graph: `blocked` and `blockedBy`.               |
| `rata search <text> [flags]`                          | Full-text search. Keeps relevance ranking; paging is best effort.              |
| `rata issue show <ref> [--comments] [--no-comments]`  | Show one issue. `view` aliases `show`. `--summary` reads headers only.         |
| `rata issue status <ref> [--json] [--fields <paths>]` | Read the summary, blockers, GitHub PRs and next unblocked child in one call.   |
| `rata issue create --title <title> [flags]`           | Create an issue.                                                               |
| `rata issue update <ref> [flags]`                     | Update an issue.                                                               |
| `rata issue section get <ref> <heading>`              | Print one section of the body. `--with-heading` adds the heading line.         |
| `rata issue section append <ref> <heading>`           | Append to a section, or create it at the end. `--level` sets a new heading.    |
| `rata issue section replace <ref> <heading>`          | Replace a section and keep its heading.                                        |
| `rata issue comment create <ref> [--body <text>]`     | Comment on an issue. `--dedupe-key` makes a retry idempotent.                  |
| `rata issue comment update <comment-id>`              | Replace one comment body. `--dry-run` prints the diff.                         |
| `rata issue comment delete <comment-id> [--yes]`      | Move one comment to the trash. JSON mode needs `--yes`.                        |
| `rata issue label add [<ref>] <label...>`             | Add labels. `--parent` targets every child; then every positional is a label.  |
| `rata issue label remove [<ref>] <label...>`          | Remove labels. The same `--parent` rule.                                       |
| `rata issue assign [<ref>] --assignee <value>`        | Assign an issue, or every child with `--parent`. `me`, a user id, or `none`.   |
| `rata issue unassign <ref>`                           | Clear the assignee.                                                            |
| `rata issue close <ref> [--comment <text>]`           | Close with an optional comment. `--comment-file -` reads stdin.                |
| `rata issue reopen <ref>`                             | Reopen.                                                                        |
| `rata issue link <ref> [flags]`                       | Create relations.                                                              |
| `rata issue unlink <ref> [flags]`                     | Remove relations.                                                              |

### Read shapes

A read of one resource prints the resource object. A collection prints
`{ <plural>, pageInfo }`. A context document keeps its named sections.

| Command                                   | JSON                                                                                                |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `issue show <ref>`                        | The issue object with `description`, `children`, `relations`, `attachments` and `comments`          |
| `issue show <ref> --summary`              | The summary object                                                                                  |
| `issue status <ref>`                      | The summary plus `blocked`, `blockedBy`, `prs` and `nextChild`                                      |
| `next --parent <ref>`                     | The summary of the ready child, or `null`                                                           |
| `why <ref>`                               | The summary plus `blocked` and `blockedBy`                                                          |
| `team show [<ref>]`                       | The team object                                                                                     |
| `issue section get <ref> <heading>`       | The section object: `heading`, `level`, `content`                                                   |
| `issue list`, `search`                    | `{ issues, pageInfo }`                                                                              |
| `team list`, `project list`, `label list` | `{ <plural>, pageInfo }`                                                                            |
| `status`                                  | The named sections `repository`, `workspace`, `viewer`, `team`, `project`, `defaults` and `warning` |
| `config show`                             | `{ defaults }`                                                                                      |
| A write                                   | The write result object                                                                             |

Every issue read carries `createdAt` and `updatedAt`, and `--fields createdAt`
selects the creation time. `--fields` starts at the object in the table: the
resource for a read, each row for a list. For `config show`, it starts at the
`defaults` object. Write commands reject the flag.

### `issue show` flags

`--comments` adds comments; `--no-comments` skips the fetch and omits the key.
`--summary` reads the header fields only and rejects `--comments`. `--no-body`,
`--no-relations`, `--no-children` and `--no-attachments` drop those parts and
skip their fetches. JSON is the issue object; `--summary` returns the lean
summary object at the top level.

### `issue list` flags

| Flag           | Meaning                                                                                                                                                                                                                                            |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--team`       | Team key or id.                                                                                                                                                                                                                                    |
| `--state`      | Workflow state name, for example `In Progress`.                                                                                                                                                                                                    |
| `--state-type` | `triage`, `backlog`, `unstarted`, `started`, `completed`, or `canceled`.                                                                                                                                                                           |
| `--priority`   | `none`, `urgent`, `high`, `medium`, `low`, or `0`-`4`.                                                                                                                                                                                             |
| `--label`      | Label name.                                                                                                                                                                                                                                        |
| `--assignee`   | `me`, or a user id.                                                                                                                                                                                                                                |
| `--project`    | Project id or name.                                                                                                                                                                                                                                |
| `--parent`     | Parent issue reference.                                                                                                                                                                                                                            |
| `--text`       | Text in the title or the description.                                                                                                                                                                                                              |
| `--unblocked`  | Only open issues with no open blocker.                                                                                                                                                                                                             |
| `--unassigned` | Only issues with no assignee.                                                                                                                                                                                                                      |
| `--sort`       | `priority`: urgent first and none last; ties go to the oldest.                                                                                                                                                                                     |
| `--include`    | `relations` adds `blocks`, `blockedBy`, `duplicates`, `duplicatedBy`, `related` and `similar` to every row. One list request per page and no per-child read; up to 250 per outgoing or inverse connection, and `related` and `similar` merge both. |
| `--limit`      | Page size. Default: 50, maximum: 250.                                                                                                                                                                                                              |
| `--after`      | Continue after a cursor from a previous page.                                                                                                                                                                                                      |
| `--all`        | Drain every page. `--limit` stays the page size.                                                                                                                                                                                                   |

`--include` accepts `relations` only. Another value is `validation` and the hint
lists the valid value. Without the flag, a row has no `relations` key. Each
outgoing or inverse connection holds up to 250 relations; `related` and
`similar` merge both. Read a row with more relations with `issue show`.

### `next` and `why` flags

`next --parent <ref>` takes `--parent` and `--fields`; `why <ref>` takes
`--fields`. Both accept the global `--json`. The JSON of `next` is the summary or
`null`; the JSON of `why` is the summary plus `blocked` and `blockedBy`. The
paths start at that object.

### `search` flags

| Flag      | Meaning                                           |
| --------- | ------------------------------------------------- |
| `--team`  | Team key or id. Default: the linked team.         |
| `--limit` | Page size. Default: 50, maximum: 250.             |
| `--after` | Continue after a cursor from a previous page.     |
| `--all`   | Drain every page. `--limit` stays the page size.  |
| `--json`  | Print `{ "issues": [...], "pageInfo": { ... } }`. |

Search keeps Linear's relevance ranking, so its paging is best effort. Keep the
search text fixed across pages.

### List JSON

Every list command prints one page by default and every page with `--all`:

```json
{
  "issues": [],
  "pageInfo": { "hasNextPage": true, "endCursor": "b2c3..." }
}
```

The plural key matches the command: `issues`, `teams`, `projects`, or `labels`.
`pageInfo.hasNextPage` says whether a next page exists. Pass
`pageInfo.endCursor` to `--after` to read it. With `--all`, `pageInfo` is
`{ "hasNextPage": false, "endCursor": null }` and `--limit` stays the page size. Keep the filters and the order
fixed across pages: a cursor is bound to its query. Lists are ordered by
creation time.

The priority sort fetches every matching issue across all pages before
`--limit` applies. With `--unblocked`, blocked issues are dropped first.

### `issue create` flags

| Flag                       | Meaning                                                                    |
| -------------------------- | -------------------------------------------------------------------------- |
| `--title`                  | Required.                                                                  |
| `--body` / `--body-file -` | Description.                                                               |
| `--team`                   | Team key or id. Default: the repository config.                            |
| `--project`                | Project. Default: the repository config.                                   |
| `--label`                  | Label name. Repeatable. Adds to the default labels.                        |
| `--no-default-labels`      | Drop the default labels for this call.                                     |
| `--parent`                 | Parent issue reference.                                                    |
| `--state`                  | Workflow state name.                                                       |
| `--assignee`               | `me`, a user id, or `none` to skip the default.                            |
| `--priority`               | `none`, `urgent`, `high`, `medium`, `low`, or `0`-`4`.                     |
| `--wait`                   | Seconds to wait for the new child under `--parent`. Default 5; 0 disables. |
| `--dry-run`                | Print the planned create without writing.                                  |

### `issue update` flags

`--title`, `--body` / `--body-file -`, `--state`, `--assignee`, `--project`,
`--parent`, `--priority`, `--append`, `--comment` / `--comment-file -`,
`--dry-run`, `--if-unchanged`. The priority values are the same as
`issue create`, and `none` clears the priority. `--append` adds the body to the
end of the description with a blank separator. `--if-unchanged <updatedAt>`
fails with `conflict` when the issue changed since that read. `--comment`
validates first, applies the issue update, then creates the comment; when the
comment fails, the issue update stays, the JSON carries `"comment": null` and
the `error` object, and the command exits with the error's code. `--dry-run`
prints the update action, the diff for `--append`, and the comment action.

### `issue comment` flags

`create` takes `--body` or `--body-file -`, `--dedupe-key`, `--wait` and
`--dry-run`. The key is scoped to the issue: rata derives a UUIDv4 from
`sha256(issueId + "\0" + key)` and skips an existing comment. JSON is
`{ "status": "created" | "skipped", "comment": ..., "visible": ... }`. The dedupe
check runs in a dry run, so a dry run can report `skipped`.

`update <comment-id>` takes `--body` or `--body-file -` and `--dry-run`; a
missing comment is `not_found`, and JSON is `{ "comment": ... }`.
`delete <comment-id>` takes `--yes` and `--dry-run`; JSON mode requires `--yes`
and prints `{ "deleted": true, "id": ... }`.

### `issue section` flags

`get` accepts `--with-heading`. `append` and `replace` take `--body` or
`--body-file -`, `--dry-run` and `--if-unchanged`; `append` also takes
`--level` (default 2). A missing heading read or replace is `not_found` and
lists the available headings. A duplicate heading is `ambiguous` and lists the
line numbers. JSON of `get` is the section object
`{ "heading", "level", "content" }` at the top level. `--dry-run` prints a
unified diff. JSON dry runs are
`{ "dryRun": true, "action": "section-append", "target", "heading", "diff" }`;
a write returns `{ "issue": { "identifier", "updatedAt" }, "section": { "heading", "level" } }`.

`replace` is the safe body write for one section: it replaces the content under
that heading and keeps the rest of the body. The body holds the content, without
the heading line, and includes any deeper heading in the section. Read the
snapshot, preview the diff, then write:

```bash
rata issue show RAT-42 --summary --json
rata issue section replace RAT-42 "Handoff log" --body-file handoff.md --dry-run
rata issue section replace RAT-42 "Handoff log" --body-file handoff.md --if-unchanged 2026-01-01T10:00:00.000Z
```

Do not rewrite the whole body for one section. `issue update --body-file`
replaces the whole body, so a heading that the new body leaves out is lost
without an error. A duplicate heading is the one exception: `replace` refuses it
as `ambiguous`, so rename one heading with `issue update --body-file` first.

### `issue link` and `issue unlink` flags

| Flag           | Meaning                                          |
| -------------- | ------------------------------------------------ |
| `--blocks`     | The other issue waits for this one. Repeatable.  |
| `--blocked-by` | This issue waits for the other one. Repeatable.  |
| `--related`    | Related, with no direction. Repeatable.          |
| `--duplicate`  | This issue duplicates the other one. Repeatable. |

### Writes

`issue create`, `issue update`, `issue section append`, `issue section replace`,
`issue comment create`, `issue comment update`, `issue comment delete`,
`issue link`, `issue unlink`, `issue assign`, `issue unassign`, `issue label add`,
`issue label remove`, `issue close`, `issue reopen`, `config set` and
`config unset` accept `--dry-run`.
It resolves the targets and prints the actions; no mutation runs. The body
writes print a unified diff.
JSON is `{ "dryRun": true, "actions": [...] }` for the single-issue forms. The
bulk forms return `{ "dryRun": true, "results": [...] }`; see **Bulk writes by
parent**.

### Read-after-write

Linear documents no read-after-write guarantee. `issue comment create` and
`issue create --parent` check that the new comment or child appears on a bounded
re-read. The default bound is 5 seconds. `--wait <seconds>` changes it and
`--wait 0` disables the check.

A timed-out check still exits 0: the mutation payload is the source of truth.
JSON adds `visible` next to `comment` or `issue`. It is `false` on timeout and
`null` when the check is disabled. `issue create` without `--parent` reports
`null`. Human mode prints a warning to stderr on timeout.

### Bulk writes by parent

`issue assign`, `issue label add` and `issue label remove` accept `--parent`.
Pass exactly one of the positional issue reference and `--parent`. With
`--parent`, every positional of a label command is a label, and the command
targets every child of the parent, open and closed, in creation order.

Rata validates every target and label before the first write: a bad reference or
a missing label aborts the batch with zero changes. The writes then run
best-effort and the command exits with the first failed result's code. JSON is:

```json
{
  "dryRun": false,
  "results": [
    { "identifier": "ABC-3", "status": "updated", "issue": { "identifier": "ABC-3" } },
    { "identifier": "ABC-4", "status": "skipped", "issue": { "identifier": "ABC-4" } },
    {
      "identifier": "ABC-5",
      "status": "failed",
      "error": { "code": "not_found", "message": "...", "hint": null }
    }
  ]
}
```

`--dry-run` reports the same results with `"dryRun": true` and writes nothing.

These writes are idempotent: a repeat exits 0 and reports `skipped` in JSON.
`unlink` with a missing relation is a skipped success. `label create` fails on a
duplicate name with `conflict` unless `--if-not-exists` returns the existing
label with `created: false`.
