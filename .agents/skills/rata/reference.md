# rata command reference

Every command, flag and JSON shape. The `rata` skill covers the first command
and the loops. `docs/agents/issue-tracker.md` covers the repository rules.

## Invocation

`rata <command> [subcommand] [flags] [arguments]`

- `<ref>` is an issue identifier (`ABC-42`), a UUID, or a `linear.app` URL.
- `--json` is global: it works before or after the subcommand.
- `--fields <paths>` selects dotted paths from a read; it needs `--json`.
- `--body-file -` and `--comment-file -` read stdin. `--dry-run` previews.
- `--limit` is the page size: 50 by default, 250 at most. `--after` continues a
  page; `--all` drains every page. The repository config supplies the default
  team and project.
- `--count` and `--ids-only` are list output flags on `issue list` and `search`;
  `next` takes `--ids-only`. Write help ends with an agent notes block: JSON,
  dry run, stdin and paging.

## JSON and errors

A single-resource read prints that object. A list prints `{ <plural>, pageInfo }`.
A context document keeps named sections. A write prints its result.

With `--json`, a failure writes `{ "error": { "code", "message", "hint" } }` to
stderr; `hint` is a string or `null`; `RATA_DEBUG=1` adds `details`. Human mode
prints `error:` and `hint:`.

Codes: `0` success, `1` internal, `2` validation, `3` not found, `4` conflict,
`5` auth, `6` retryable. A bulk write exits with the first failure's code, or
`0`. Two cases write a partial result to stdout: a bulk write, and a failed
`issue update --comment` with the issue update, `"comment": null` and the
`error`.

## Setup

`auth login --with-token [--workspace <name>]` saves a key from stdin;
`auth status`, `auth logout`, `workspace list` and `workspace use <name>`
manage it; `whoami` shows the viewer; `unlink` removes the link and defaults.
`status` prints the repo, workspace, key source, team, project, defaults, viewer
and org. `link [--team] [--project] [--workspace] [--create --name]` links the
repo; without `--team` it prompts and sets the team timezone. `config show`,
`config set` and `config unset` manage the issue defaults; `--label` replaces
the list.

The key resolves as `LINEAR_API_KEY`, the repository `workspace`, then
`default`. A stale team key resolves by id, key, then name: a read repairs a
changed key and warns; `status` keeps the warning. A key that no longer exists
fails a read with `not_found` and the repair hint; `status` exits 0 with `team`
and `defaults` at `null`. A legacy `.rata.json` is imported and removed on first
use; a failed remove warns.

## Teams, projects and labels

`team list [--limit] [--after] [--all]`; `team show [<ref>]` gives states, labels,
members and priorities; `team create --name <name> [--key]`; `team delete <key>
[--yes]`. `project list [--team] [--include-archived] [--limit] [--after]
[--all]`; `project create --name <name> [--team]`; `project delete <ref>
[--yes]`; `project restore <ref>`. `label list [--team] [--limit] [--after]
[--all]`; `label create --name <name> [--color] [--team] [--if-not-exists]`;
`label edit <ref> [--name] [--color] [--team]`.

## Issues

### Read shapes

| Command                                   | JSON                                                                                                               |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `issue show <ref>`                        | The issue object with `description`, `children`, `relations`, `attachments` and `comments`                         |
| `issue show <ref> --summary`              | The summary object                                                                                                 |
| `issue status <ref>`                      | The summary plus `blocked`, `blockedBy`, `prs` and `nextChild`; flags add `description`, `comments` and `children` |
| `next --parent <ref>`                     | The summary of the ready child, or `null`; `--ids-only` prints the identifier or nothing                           |
| `why <ref>`                               | The summary plus `blocked` and `blockedBy`                                                                         |
| `team show [<ref>]`                       | The team object                                                                                                    |
| `issue section get <ref> <heading>`       | `{ "heading", "level", "content" }`                                                                                |
| `issue list`, `search`                    | `{ issues, pageInfo }`; `--count` gives `{ count }`; `--ids-only` prints identifiers                               |
| `team list`, `project list`, `label list` | `{ <plural>, pageInfo }`                                                                                           |
| `status`                                  | Named sections: `repository`, `workspace`, `viewer`, `team`, `project`, `defaults`, `warning`                      |
| `config show`                             | `{ defaults }`                                                                                                     |
| `auth status`                             | `{ authenticated, source, profile, storePath, viewer }`                                                            |
| `link`                                    | `{ team, project, workspace, timezone }`                                                                           |

Every issue read carries `createdAt` and `updatedAt`. The summary carries the
identifier, title, state, priority, labels, assignee, project, parent and url.
`issue status` carries Linear `github` attachments as `prs`; `checks` and
`mergeCommit` are `null`, and each PR says `source: "linear"`.

### Field selection

`--fields` selects dotted paths from a read and needs `--json`. It starts at the
resource, at each list row, at `defaults` for `config show`, and at the whole
document for `status`. The command validates a declared shape before it reads the
value, so an unknown path is `validation` even on an empty list or a null
object; `details` carries `path` and `validPaths`. Writes reject it with a hint.

A path through a null object returns `null`. An array is selectable whole. A
path may cross an array: a final array segment returns the array; a later segment
maps each element; a scalar leaf returns an array of scalars (`labels.name` ->
`["bug"]`); an object leaf returns an array of objects (`children.state` ->
`[{ "state": ... }]`); paths that cross the same array merge. A path through an
array of scalars is `validation`; an empty array returns `[]`. A list keeps
`pageInfo`. Valid on `status`, `issue show`, `issue status`, `next`, `why`,
`issue section get`, `issue list`, `search`, `team show`, `team list`,
`label list`, `project list` and `config show`.

### `issue show` flags

`--comments` adds comments; `--no-comments` skips the fetch and omits the key;
the two conflict. `--summary` reads header fields only and rejects `--comments`.

`--no-body` drops the description from the output only; the read still fetches
it. `--no-relations`, `--no-children` and `--no-attachments` drop those parts and
skip their fetches. JSON is the issue object, not a wrapper; `view` aliases
`show`; every collection page is read.

### `issue status` flags

The default read uses two requests: the detail and one ready child. `--with-body`
adds `description` at no extra request. `--comments` adds `comments` with one
extra request. `--children` replaces the one-child read with every child, each
with `blocked` and `blockedBy`, and computes `nextChild` from them. `--fields`
follows the flags: `description`, `comments` and `children` each need their flag.

### `issue list` flags

`--team`, `--state`, `--state-type`, `--priority`, `--label`, `--assignee`,
`--project`, `--parent`, `--id`, `--text`, `--unblocked` and `--unassigned`
filter; `--limit`, `--after` and `--all` page.

`--id <ref>` reads exact refs and repeats for a batch. Exact refs bypass the
linked team; `--team` narrows. It composes with `--fields`, `--include
relations`, `--all`, `--count` and `--ids-only`. A missing ref is `not_found`
once the read covers every page; add `--all` to check a batch completely.

On an empty page, `--state`, `--label` and `--project` are checked for
existence. An unknown name is `not_found` with the valid names; a valid name
with no matches stays empty. `--assignee` accepts `me` or a user UUID; a
malformed value is `validation`, an unknown UUID is `not_found`.

`--count` drains every page and prints `{ "count": n }`; `--ids-only` prints one
identifier per line. They cannot combine, `--count` rejects `--fields`, and
`--ids-only` rejects `--json` and `--fields`. `search` accepts both.

`--sort priority` orders urgent first and none last; Linear sorts on the server
and ties go to the oldest. `--limit` stays the page size and `--after` continues
the sorted result. `--unblocked` drops blocked issues first.

`--include relations` adds the six groups to every row with one request per page
and no per-child read. Each outgoing or inverse connection holds up to 250, and
`related` and `similar` merge both. A full page is 2,462 complexity points at
page sizes 10, 25 and 50, under the 10,000-point cap. Read a larger row with
`issue show`. Without the flag a row has no `relations` key; another value is
`validation`.

### `next`, `why` and `search`

`next --parent <ref>` returns the first open, unblocked, unassigned child:
priority first, then oldest `createdAt`. JSON is the summary or `null`; both exit 0. `--ids-only` prints the identifier or nothing.

`why <ref>` returns the summary plus `blocked` and `blockedBy`; each blocker
carries its state and `closed`, and `blocked` is true when any is open.

`search <text>` takes `--team`, `--limit`, `--after`, `--all`, `--count` and
`--ids-only`; it keeps relevance order, so paging is best effort.

### Paging

Every list prints one page: `--limit` is the page size, `--after` continues from
`pageInfo.endCursor`, and `--all` drains with `pageInfo`
`{ "hasNextPage": false, "endCursor": null }`. Keep the filters and order fixed;
a cursor is bound to its query.

## Issue writes

The focused writes: `issue assign [<ref>...] --assignee <me|none|id> [--parent]`,
`issue unassign <ref>`, `issue label add|remove [<ref>] <label...> [--parent]`,
`issue close <ref> [--comment <text>] [--comment-file -]`, `issue reopen <ref>`.
All take `--dry-run`.

### `issue create` flags

`--title` is required. `--body` or `--body-file -` sets the description.
`--team` and `--project` default to the repository config. `--label` repeats and
adds to the default labels; `--no-default-labels` drops them for one call. Also
`--parent`, `--state`, `--assignee` (`me`, a user id, or `none`), `--priority`
(`none`, `urgent`, `high`, `medium`, `low`, or `0`-`4`), `--wait` (seconds,
default 5, 0 disables) and `--dry-run`.

### `issue update` flags

`--title`, `--body` or `--body-file -`, `--state`, `--assignee`, `--project`,
`--parent`, `--priority`, `--append`, `--sections-file`, `--comment` or
`--comment-file -`, `--dry-run` and `--if-unchanged`.

`--append` adds the body with a blank separator. `--if-unchanged <updatedAt>`
fails with `conflict` when the issue changed since that read. `--comment`
validates, applies the update, then creates the comment; when the comment fails,
the update stays, JSON carries `"comment": null` and the `error`, and the exit
code is the error's.

`--sections-file -` reads `{ "sections": [{ "heading", "content" }] }` and
replaces every heading in one read, one diff and one write. The heading line and
deeper headings stay. A missing heading is `not_found`, a duplicate is
`ambiguous`, and an empty heading is `validation`; every heading is checked
before the first write. It cannot combine with `--body`, `--body-file` or
`--append`; it composes with the other fields, `--comment`, `--if-unchanged` and
`--dry-run`. The dry run prints `{ "dryRun": true, "status", "updatedAt",
"sections", "diff" }`; `updatedAt` is the snapshot. The write prints
`{ "status", "updatedAt", "issue", "sections" }`, and each section action is
`replaced` or `skipped`.

### `issue section` flags

`get` takes `--with-heading`. `append` and `replace` take `--body` or
`--body-file -`, `--dry-run` and `--if-unchanged`; `append` also takes `--level`
(default 2). A missing read or replace is `not_found` with the available
headings; a duplicate is `ambiguous` with the line numbers. JSON of `get` is the
section object at the top level.

`replace` is the one-section write: the body holds the content without the
heading line and includes deeper headings. Take `updatedAt` from a read, preview
with `--dry-run`, then write with `--if-unchanged`. Never rewrite the whole body
for one section: `issue update --body-file` drops every heading the new body
leaves out. For several sections, use `issue update --sections-file -`. The
`issue update` form takes one snapshot, one diff and one write.

### `issue comment` flags

`create` takes `--body` or `--body-file -`, `--dedupe-key`, `--wait` and
`--dry-run`. The key is scoped to the issue: rata derives a UUIDv4 from
`sha256(issueId + "\0" + key)` and skips an existing comment. JSON is
`{ "status": "created" | "skipped", "comment": ..., "visible": ... }`; a dry run
runs the dedupe check. `update <comment-id>` takes `--body` or `--body-file -`
and `--dry-run`; a missing comment is `not_found`; JSON is
`{ "comment": ... }`. `delete <comment-id>` takes `--yes` and `--dry-run`; JSON
mode requires `--yes` and prints `{ "deleted": true, "id": ... }`.

### `issue link` and `issue unlink` flags

`--blocks`, `--blocked-by`, `--related` and `--duplicate` repeat. `--blocks X`
records that the issue blocks X; `--blocked-by X` records that X blocks the
issue; `--duplicate X` means the issue duplicates X; `--related X` links the two
with no direction. The command resolves the source and every target in one id
query, reads both relation directions in one query, and needs no id query for a
UUID. One target and three targets each cost two read requests in the common
case. A missing relation on `unlink` is a skipped success.

## Dry runs

Every issue write accepts `--dry-run`; no mutation runs. `config set` and
`config unset` also take it.

| Command                                                                                                                                                                                              | JSON                                                            |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `issue create`, `issue update`, `issue link`, `issue unlink`, `issue assign`, `issue unassign`, `issue label add`, `issue label remove`, `issue close`, `issue reopen`, `config set`, `config unset` | `{ "dryRun": true, "actions": [...] }`                          |
| `issue update --sections-file`                                                                                                                                                                       | `{ "dryRun": true, "status", "updatedAt", "sections", "diff" }` |
| `issue comment create`                                                                                                                                                                               | `{ "dryRun": true, "action", "target", "status", "changes" }`   |
| `issue comment update`                                                                                                                                                                               | `{ "dryRun": true, "action", "target", "diff" }`                |
| `issue comment delete`                                                                                                                                                                               | `{ "dryRun": true, "action", "target", "comment" }`             |
| `issue section append`, `issue section replace`                                                                                                                                                      | `{ "dryRun": true, "action", "target", "heading", "diff" }`     |
| Bulk `issue assign`, `issue label add`, `issue label remove`                                                                                                                                         | `{ "dryRun": true, "results": [...] }`                          |

Each generic action carries `action`, `target` and `changes`. Body writes print a
unified diff; `issue update --comment` prints the planned update and comment.
`issue update --sections-file` is the one dry run with the snapshot `updatedAt`.

## Write results

| Command                                                                                  | JSON                                                                                                                                         |
| ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `issue create`                                                                           | `{ "issue": { ... }, "visible": true \| false \| null }`                                                                                     |
| `issue update`                                                                           | `{ "issue": { ... } }`; with `--comment`, `{ "issue", "comment" }`; with `--sections-file`, `{ "status", "updatedAt", "issue", "sections" }` |
| `issue close`, `issue assign`, `issue unassign`, `issue label add`, `issue label remove` | `{ "dryRun": false, "status": "updated" \| "skipped", "issue": { ... } }`                                                                    |
| `issue reopen`                                                                           | `{ "issue": { ... } }`                                                                                                                       |
| `issue link`, `issue unlink`                                                             | `{ "dryRun": false, "status", "relations": [...] }`                                                                                          |
| `issue comment create`                                                                   | `{ "status", "comment", "visible" }`                                                                                                         |
| `issue comment update`, `issue comment delete`                                           | `{ "comment": { ... } }`; delete gives `{ "deleted": true, "id": ... }`                                                                      |
| `issue section append`, `issue section replace`                                          | `{ "issue": { "identifier", "updatedAt" }, "section": { "heading", "level" } }`                                                              |
| `config set`, `config unset`                                                             | `{ "dryRun": false, "defaults": { ... } }`                                                                                                   |

The summary in a write result carries `id`, `identifier`, `title`, `url`,
`state`, `priority`, `assignee`, `project`, `parent`, `labels`, `createdAt` and
`updatedAt`. The `--sections-file` result carries one `{ heading, action }` per
section; with `--comment`, it adds `comment`. A link result carries `status` and
one `{ action, kind, target }` per change.

## Read-after-write

`issue comment create` and `issue create --parent` check that the new object
appears on a bounded re-read. The default is 5 seconds; `--wait <seconds>`
changes it and `--wait 0` disables it. A timeout still exits 0: the mutation
payload is the source of truth. JSON adds `visible`: `false` on timeout and
`null` when disabled.

## Bulk writes by parent

`issue assign`, `issue label add` and `issue label remove` accept `--parent`;
pass exactly one of the positional reference and `--parent`. With `--parent`,
every positional of a label command is a label, and the command targets every
child, open and closed, in creation order.

Rata validates every target and label before the first write, then runs
best-effort and exits with the first failed result's code. JSON prints
`{ "dryRun": false, "results": [...] }`; a failed result carries `error`, and
`status` is `updated`, `skipped` or `failed`.

## Idempotency

A write that finds the desired state in place exits 0 and reports `skipped`;
this covers `link`, `unlink`, `assign`, `unassign`, both label commands, `close`
and `reopen`. A `canceled` issue still moves to a completed state, and a close
with a comment still posts it. `issue create` always creates a new object.
`label create` fails on a duplicate name with `conflict` unless `--if-not-exists`
returns it with `created: false`.

## Executable hints

A known wrong form fails with `validation` before any request, keeps the JSON
error shape, and prints one hint that names the command to run. A supplied body,
label or relation value stays in the hint, shell-quoted when needed.

| Wrong form                                 | Hint                                                                       |
| ------------------------------------------ | -------------------------------------------------------------------------- |
| `issue <ref>`                              | `rata issue show <ref>`                                                    |
| `issue comment <ref>`                      | `rata issue comment create <ref> --body-file -`                            |
| `issue update <ref> --label <label...>`    | `rata issue label add <ref> <label...>`                                    |
| `issue create --blocked-by <ref>`          | `Create the issue, then run rata issue link <new-ref> --blocked-by <ref>.` |
| `issue update <ref> --blocked-by <ref>`    | `rata issue link <ref> --blocked-by <ref>`                                 |
| `issue link <ref>` without a relation flag | `rata issue link <ref> --blocked-by <blocker>`                             |
| a write with `--fields`                    | `--fields applies to reads only. Use --json and jq on the write result.`   |
