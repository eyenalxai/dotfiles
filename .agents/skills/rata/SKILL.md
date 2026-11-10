---
name: rata
description: Drive Linear from the terminal with the rata CLI — read and write issues, comments, labels, relations, and wayfinding maps. Use when a repository tracks work in Linear, when its docs/agents/issue-tracker.md names rata, or when the user asks to file, triage, comment on, link, block, claim, or close Linear issues.
---

# rata

`rata` is the Linear CLI for agent workflows. It backs the `ask-matt`
engineering skills when a repository tracks its work in Linear.

Read `docs/agents/issue-tracker.md` in the repository first: it names the team,
the label vocabulary, and the publishing conventions for that repository. This
skill covers the CLI itself.

## One way per operation

Each operation has one canonical form. A different spelling fails with one hint
that names the canonical form. Read the hint and retry; do not guess a second
form.

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
execution.

## Read shapes

One rule: a read of one resource prints that resource. A collection prints
`{ <plural>, pageInfo }`. A context document keeps its named sections.

| Command                                   | JSON                                                                                                   |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `issue show <ref>`                        | The issue object: its fields plus `description`, `children`, `relations`, `attachments` and `comments` |
| `issue show <ref> --summary`              | The summary object                                                                                     |
| `issue status <ref>`                      | The summary plus `blocked`, `blockedBy`, `prs` and `nextChild`                                         |
| `next --parent <ref>`                     | The summary of the ready child, or `null`                                                              |
| `why <ref>`                               | The summary plus `blocked` and `blockedBy`                                                             |
| `team show [<ref>]`                       | The team object                                                                                        |
| `issue section get <ref> "<heading>"`     | The section object: `heading`, `level`, `content`                                                      |
| `issue list`, `search`                    | `{ issues, pageInfo }`                                                                                 |
| `team list`, `project list`, `label list` | `{ <plural>, pageInfo }`                                                                               |
| `status`                                  | The named sections `repository`, `workspace`, `viewer`, `team`, `project`, `defaults` and `warning`    |
| `config show`                             | `{ defaults }`                                                                                         |
| A write                                   | The write result object                                                                                |

`--fields` starts at that object: the resource for a read, each row for a list.
For `config show`, it starts at the `defaults` object. Write commands reject the
flag. `pageInfo` stays in a list result. A path through a null object returns
`null`; `assignee.name` on an unassigned issue gives `{"assignee": null}`. An
array is selectable as a whole, such as `labels`, but a path into an array is a
validation error. An unknown path is a validation error whose hint lists the
valid keys at the failing level. The flag needs `--json`, and it is valid on
`status`, `issue show`, `issue status`, `next`, `why`, `issue section get`,
`issue list`, `search`, `team show`, `team list`, `label list`, `project list`
and `config show`.

`issue list --include relations` adds the six relation groups to every row:
`blocks`, `blockedBy`, `duplicates`, `duplicatedBy`, `related` and `similar`.
The flag sends one list request per page and no per-child read. Each outgoing or
inverse connection holds up to 250 relations; `related` and `similar` merge
both. Read a larger row with `issue show`. The flag accepts `relations` only,
and another value fails with a hint that lists it.

## Set up a repository

Link the repository to its team once:

```bash
rata link --team ABC
```

`link` stores the repository config in rata's local database, so every later
command knows the team from any subdirectory, and every worktree shares it. Use
`--create --name "<name>"` when the team does not exist yet. Without `--team`,
`link` asks for the workspace first, then the team. When the key exists in more
than one stored workspace, pass `--workspace <name>` to choose one.

On first use, rata imports a legacy `.rata.json` into the database and removes
the file. When the remove fails, rata prints a warning on standard error and
keeps the file; the command still succeeds. A file that is already gone is not an
error.

When the stored team key no longer exists, `status` exits 0 and still reports
the rest of the context. `team` and `defaults` are `null`, and `warning` names
the stale key and the repair. Run `rata team list`, then
`rata link --team <key>`.

## Read before you write

```bash
rata status --json                        # repo, workspace, team, defaults, viewer and org
rata config show --json                   # issue defaults for this repository
rata team show --json                     # states, labels, members and priorities
rata issue list --json                    # list issues; returns one page
rata issue list --json --fields identifier,title,state.name  # select fields per row
rata issue list --all --json              # drain every page
rata issue list --after <cursor> --json   # read the next page
rata issue list --parent ABC-50 --include relations --json  # rows with blocking edges
rata issue show ABC-42 --json             # comments, children, relations, attachments
rata issue status ABC-42 --json           # summary, blockers, PRs and the next child
rata issue view ABC-42 --summary --json   # lean header read; `view` aliases `show`
rata issue section get ABC-42 "Handoff log"  # one heading section of the body
rata search "flaky test" --json
```

`team show` without a reference uses the linked team. Pass a key or id for
another team. Do not guess a workflow state name: read it from `team show`.

An issue reference is an identifier (`ABC-42`), a UUID, or a `linear.app` URL.
`--json` is global: it works before or after the subcommand. Parse that, not the
human output. A read of one resource prints the resource object. A failed
`--json` command writes one `error` object (`code`, `message`, `hint`) to stderr
and exits with the code of its class: 2 validation, 3 not found, 4 conflict, 5
auth, 6 retryable, 1 internal. List commands return one page with `pageInfo`: see
**Paging lists**.

`issue show` has `--summary`, `--no-body`, `--no-relations`, `--no-children` and
`--no-attachments`. `--summary` reads the header fields only and rejects
`--comments`. The `--no-*` flags drop those parts and skip their fetches. `view`
is an alias for `show`. JSON is the issue object, not a wrapper.

Every issue carries `createdAt` and `updatedAt`. `createdAt` is the Linear
creation time; it is in every issue read (`issue list`, `issue show` and its
summary, `issue status`, `search`, `next`, `why`). `--fields createdAt` selects
it. Pass `updatedAt` to `--if-unchanged <updatedAt>` on `issue update` or
`issue section append|replace` to fail with `conflict` when the issue changed
since that read. Linear has no compare-and-swap, so the check is best effort.

`issue status` is the one read for a session start. It returns the issue summary
as one flat object, plus `blocked`, `blockedBy`, `prs` and `nextChild`. The PR
projection reads the Linear `github` attachments: each PR carries its number,
repo, url, status, draft flag, reviews, conflict flag, `mergedAt` and `closedAt`.
`checks` and `mergeCommit` are `null`, and each PR says `source: "linear"`, so the
command needs no GitHub token. `nextChild` is the first open, unblocked child
ordered by priority, then creation time; it ignores the assignee, unlike `next`.

Edit one section of the body with `issue section replace`. It is the safe body
write: it replaces the content under one heading and keeps the rest of the body.
The heading match is exact and case-sensitive. Read the issue for `updatedAt`,
preview the diff, then write against that snapshot:

```bash
rata issue show ABC-42 --summary --json
rata issue section replace ABC-42 "Handoff log" --body-file handoff.md --dry-run
rata issue section replace ABC-42 "Handoff log" --body-file handoff.md --if-unchanged <updatedAt>
```

The file holds the content under the heading, without the heading line. A deeper
heading belongs to that section, so write it too. Do not rewrite the whole body
for one section: `issue update --body-file` replaces the whole body and drops
every heading that the new body leaves out, without an error. `issue section
append` adds to the end of a section, or creates a missing heading, and
`--level` sets its level. `issue section get` reads the content back;
`--with-heading` adds the heading line.

A comment or a child that a write just created can be missing from the next
read. `issue comment create` and `issue create --parent` check for up to 5
seconds. `--wait <seconds>` changes the bound and `--wait 0` skips the check.
JSON reports `visible`: `null` means unchecked, `false` means not seen. The
write itself still succeeded.

## Paging lists

`issue list`, `search`, `team list`, `project list` and `label list` return one
page per call. `--limit` is the page size: 50 by default, 250 at most.
`--after <cursor>` reads the next page. Add `--all` to drain every page;
`--limit` stays the page size and `--after` starts from the cursor. JSON is
`{ <plural>, pageInfo }`:

```json
{
  "issues": [],
  "pageInfo": { "hasNextPage": true, "endCursor": "b2c3..." }
}
```

Continue with `--after b2c3...` while `pageInfo.hasNextPage` is true, or add
`--all` for the full set. With `--all`, `pageInfo` is
`{ "hasNextPage": false, "endCursor": null }`. Keep the filters and the order
fixed across pages: a cursor is bound to its query. Lists are ordered by
creation time; `search` keeps Linear's relevance ranking, so its paging is best
effort. The human output prints a next-page hint when more results exist.
Internal reads drain every page, so `issue show` is complete.

## Triage

Triage roles are labels. Apply one state and one category:

```bash
rata issue label add ABC-42 ready-for-agent
rata issue label remove ABC-42 needs-triage
```

States: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`,
`wontfix`. Categories: `bug`, `enhancement`.

Repair every child of a spec in one call. `--parent` targets all children, open
and closed, and makes every positional of a label command a label:

```bash
rata issue label add --parent ABC-60 ready-for-agent
rata issue assign --parent ABC-60 --assignee me
```

Maps stay unassigned until the claim step: label a map's children in bulk, but
claim them one by one. A bad reference or a missing label aborts the batch before
any write. Add `--dry-run` to preview.

Set a priority on every actionable issue (`ready-for-agent` or
`ready-for-human`):

| Priority | When                                             |
| -------- | ------------------------------------------------ |
| `urgent` | The issue breaks production or blocks a release. |
| `high`   | The issue blocks other work.                     |
| `medium` | The fallback when no other value applies.        |
| `low`    | Nice-to-have.                                    |

```bash
rata issue update ABC-42 --priority high
```

`needs-info` and `wontfix` issues may stay `none`.

Post the reasoning as a comment. `--body-file -` reads markdown from stdin, so
long bodies never touch the command line:

```bash
rata issue comment create ABC-42 --body-file - <<'EOF'
## Triage

...
EOF
```

`issue comment create` is retry-safe with `--dedupe-key`. The key is scoped to
the issue, so a retried handoff comment returns the one already posted with
`status: "skipped"`:

```bash
rata issue comment create ABC-42 --body "Handoff." --dedupe-key mission-42-handoff
```

Use the mission and ticket in the key, for example
`mission-<spec>-<ticket>-handoff`, so a retry reuses the comment and a new
ticket gets its own. Rewrite or remove a comment with
`issue comment update <comment-id>` and `issue comment delete <comment-id> --yes`.
To change the issue and comment in one call, add `--comment` to `issue update`:

```bash
rata issue update ABC-42 --state Done --comment "Shipped in PR #12."
```

Close a `wontfix` with `rata issue close ABC-42 --comment "..."`.

## Publish tickets

```bash
rata issue create --title "Fix the flaky test" --label ready-for-agent --label bug --body-file - <<'EOF'
## What to build

...
EOF
```

`create` resolves the team and project from the repository config, which
`rata link` writes. Override them with `--team` and `--project`. The repository
issue defaults fill the assignee, labels and priority. Set them once:

```bash
rata config set --assignee me --label enhancement --priority medium
```

`--label` adds to the default labels; `--no-default-labels` drops them for one
call. `--assignee none` and `--priority none` clear their defaults.

Wire blocking edges as you publish. Linear has one `blocks` relation, so
`--blocked-by` records it in the direction you mean:

```bash
rata issue link ABC-43 --blocked-by ABC-42   # ABC-43 waits for ABC-42
```

## Specs and tickets

A spec is an issue. Do not wrap it in a project and do not put `Spec:` in the
title. Its tickets are child issues of the spec, so the set stays together:

```bash
rata issue create --title "Switch billing to Stripe" --label ready-for-agent --priority medium --body-file -
rata issue create --title "Add the Stripe client" --parent ABC-50 --label ready-for-agent --priority medium --body-file -
rata issue create --title "Switch the webhooks" --parent ABC-50 --label ready-for-agent --priority medium --body-file -
rata issue link ABC-52 --blocked-by ABC-51
rata issue list --parent ABC-50 --all --json --include relations
```

Each list row then carries its blocking edges, so the frontier needs no
per-child read. `issue show <spec-ref> --json` also lists the child issues. A
wayfinding map stays an issue with child issues; a map is not a spec.

## Wayfinding

A map is an issue labelled `wayfinder:map`. Its tickets are children labelled
`wayfinder:<type>`, where type is `research`, `prototype`, `grilling`, or
`task`.

```bash
rata issue create --title "Map: switch billing to Stripe" --label wayfinder:map --no-default-labels --assignee none
rata issue create --parent ABC-50 --title "Research: Stripe webhook retries" --label wayfinder:research --no-default-labels --assignee none
```

Maps and children stay unassigned and carry only `wayfinder:*` labels. The
priority default still applies.

Claim a ticket by assigning yourself. Resolve it with a comment, then close it:

```bash
rata issue assign ABC-51 --assignee me
rata issue comment create ABC-51 --body-file - <<'EOF'
## Answer

...
EOF
rata issue close ABC-51
```

The frontier is the set of tickets under a map that are open, unblocked and
unassigned. Read the first ready ticket with:

```bash
rata next --parent ABC-50
```

The JSON is the summary of the ready child, or `null` when the frontier is
empty. Human output prints the ticket line, or `No ready ticket.`; both exit 0.
`next` reads every matching page before it picks: priority first (urgent
first), then the oldest `createdAt`. `next` accepts `--fields`; the paths start
at the summary.

Check why a ticket is not ready with `rata why ABC-51`. The JSON is the summary
plus `blocked`, which is true when any blocker is open, and `blockedBy`, where
each blocker names its state and whether it is `closed`. Human output prints
`ABC-51 is ready.` when nothing blocks. `why` accepts `--fields`; the paths
start at the same object.

## Reference

[`reference.md`](reference.md) lists every command and flag.
