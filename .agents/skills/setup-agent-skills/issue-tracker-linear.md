# Issue tracker: Linear

Issues and specs for this repository live in Linear, team `<TEAM>`
(`<TEAM NAME>`), workspace `<WORKSPACE>`. Use the `rata` CLI for every tracker
operation.

Load the rata skill before the first tracker command. It holds the canonical
forms, the read loop and the write loop. This file holds the repository facts.

## Repository link

Run `rata link --team <TEAM> --workspace <WORKSPACE>` once from the repository
root. The link lives in rata's local database, so every subdirectory and worktree
finds it. Run `rata status --json` to read the team, the issue defaults and the
viewer.

When the stored team key is stale, a read warns and repairs the link. When the
key no longer exists, the read fails with `not_found`; run `rata team list`, then
`rata link --team <key> --workspace <WORKSPACE>`.

## Labels

Every live issue carries one category label and one state label. The default
labels are `bug` and `enhancement` for category, and `needs-triage`,
`needs-info`, `ready-for-agent`, `ready-for-human` and `wontfix` for state.
Change the names here when the team uses other strings; the role mapping lives
in `docs/agents/triage-labels.md`.

Apply and remove labels with `rata issue label add <ref> <label...>` and
`rata issue label remove <ref> <label...>`.

## Priority and assignee

Every actionable issue carries a priority: `urgent`, `high`, `medium` or `low`.
Every actionable issue is assigned to the owner. Pass `--priority` and
`--assignee me` on create; change them later with
`rata issue update <ref> --priority <value>` and
`rata issue assign <ref> --assignee me`.

Wayfinder maps and children are the exception: they stay unassigned until the
claim step and carry no triage labels. Create them with `--no-default-labels`
and `--assignee none`.

## Specs and tickets

A spec is an issue. Do not create a project for it and do not put `Spec:` in the
title. Its tickets are its child issues.

- **Publish a spec**: `rata issue create --title "<title>" --label ready-for-agent --priority medium --assignee me --body-file -`.
- **Publish the tickets**: add `--parent <spec-ref>` and the same label,
  priority and assignee to each create.
- **Wire blocking edges**: `rata issue link <ticket-ref> --blocked-by <blocker-ref>`.
- **Read the set**: `rata issue list --parent <spec-ref> --all --json --include relations`.
- **Read known tickets**: `rata issue list --id <ref> --id <ref> --json`.
- **Start a ticket**: `rata issue status <ticket-ref> --json --with-body`, then
  claim it with `rata issue assign <ticket-ref> --assignee me`.
- **Replace record sections**: `rata issue update <spec-ref> --sections-file -`
  with `{"sections":[{"heading":"...","content":"..."}]}`. Preview with
  `--dry-run`, then write with `--if-unchanged <updatedAt>`.
- **Close the spec**: when every ticket is Done, close the spec with
  `rata issue close <spec-ref> --comment "..."`.

## Wayfinding operations

A map is an issue labelled `wayfinder:map`. Its tickets are child issues with a
`wayfinder:<type>` label: `research`, `prototype`, `grilling` or `task`.

- **Map**: `rata issue create --title "..." --label wayfinder:map --no-default-labels --assignee none --body-file -`.
- **Child**: add `--parent <map-ref>` and the type label.
- **Frontier**: `rata issue list --parent <map-ref> --unblocked --unassigned --all --json --include relations --sort priority`.
- **Claim**: `rata issue assign <ref> --assignee me`.
- **Resolve**: `rata issue comment create <ref> --body-file -`, then
  `rata issue close <ref>`, then append the context pointer to the map's
  Decisions-so-far section with
  `rata issue section append <map-ref> "Decisions so far" --body-file -`.

## Pull requests

**PRs as a request surface: no.** Linear holds issues only. When this
repository treats external pull requests as feature requests, triage them where
they live and mirror the outcome here.

Describe the pull request host, base branch, branch name, title, body and closing
word for this repository.
