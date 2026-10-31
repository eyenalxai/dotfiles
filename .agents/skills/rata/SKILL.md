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

## Read before you write

```bash
rata status --json                        # repo, workspace, team, defaults, viewer and org
rata config show --json                   # issue defaults for this repository
rata team show --json                     # states, labels, members and priorities
rata issue list --json                    # list issues; returns one page
rata issue list --all --json              # drain every page
rata issue list --after <cursor> --json   # read the next page
rata issue show ABC-42 --json             # comments, children, relations, attachments
rata issue view ABC-42 --summary --json   # lean header read; `view` aliases `show`
rata issue section get ABC-42 "Handoff log"  # one heading section of the body
rata search "flaky test" --json
```

`team show` without a reference uses the linked team. Pass a key or id for
another team. Do not guess a workflow state name: read it from `team show`.

An issue reference is an identifier (`ABC-42`), a UUID, or a `linear.app` URL.
`--json` is global: it works before or after the subcommand. Parse that, not the
human output. `--fields` trims a read to dotted paths, for example
`rata issue list --json --fields identifier,title,state.name`. A failed `--json`
command writes one `error` object (`code`, `message`, `hint`) to stderr and
exits with code 1. List commands return one page with `pageInfo`: see **Paging
lists**.

`issue show` has `--summary`, `--no-body`, `--no-relations`, `--no-children` and
`--no-attachments`. `--summary` reads the header fields only and rejects
`--comments`. The `--no-*` flags drop those parts and skip their fetches. `view`
is an alias for `show`.

Every issue carries `updatedAt`. Pass it to `--if-unchanged <updatedAt>` on
`issue update` or `issue section append|replace` to fail with `conflict` when
the issue changed since that read. Linear has no compare-and-swap, so the check
is best effort.

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
rata issue list --parent ABC-50 --all --json
```

`issue show <spec-ref> --json` also lists the child issues. A wayfinding map
stays an issue with child issues; a map is not a spec.

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

The JSON is `{ issue }`. `issue` is the summary, or `null` when the frontier is
empty. Human output prints the ticket line, or `No ready ticket.`; both exit 0.
`next` reads every matching page before it picks: priority first (urgent
first), then the oldest `createdAt`.

Check why a ticket is not ready with `rata why ABC-51`. The JSON carries
`blocked`, which is true when any blocker is open, and `blockedBy`, where each
blocker names its state and whether it is `closed`. Human output prints
`ABC-51 is ready.` when nothing blocks.

## Reference

[`reference.md`](reference.md) lists every command and flag.
