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

## Read before you write

```bash
rata issue list --json                    # the default team's open issues
rata issue show PER-42 --comments --json  # one issue with its comments
rata search "flaky test" --json
```

An issue reference is an identifier (`PER-42`), a UUID, or a `linear.app` URL.
Every command supports `--json`; parse that, not the human output.

## Triage

Triage roles are labels. Apply one state and one category:

```bash
rata issue label add PER-42 ready-for-agent
rata issue label remove PER-42 needs-triage
```

States: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`,
`wontfix`. Categories: `bug`, `enhancement`.

Post the reasoning as a comment. `--body-file -` reads markdown from stdin, so
long bodies never touch the command line:

```bash
rata issue comment PER-42 --body-file - <<'EOF'
## Triage

...
EOF
```

Close a `wontfix` with `rata issue close PER-42 --comment "..."`.

## Publish tickets

```bash
rata issue create --title "Fix the flaky test" --label ready-for-agent --label bug --body-file - <<'EOF'
## What to build

...
EOF
```

`create` resolves the team and project from `.rata.json`, which `rata init`
writes. Override them with `--team` and `--project`.

Wire blocking edges as you publish. Linear has one `blocks` relation, so
`--blocked-by` records it in the direction you mean:

```bash
rata issue link PER-43 --blocked-by PER-42   # PER-43 waits for PER-42
```

## Wayfinding

A map is an issue labelled `wayfinder:map`. Its tickets are children labelled
`wayfinder:<type>`, where type is `research`, `prototype`, `grilling`, or
`task`.

```bash
rata issue create --title "Map: switch billing to Stripe" --label wayfinder:map
rata issue create --parent PER-50 --title "Research: Stripe webhook retries" --label wayfinder:research
```

Claim a ticket by assigning yourself. Resolve it with a comment, then close it:

```bash
rata issue assign me PER-51
rata issue comment PER-51 --body-file - <<'EOF'
## Answer

...
EOF
rata issue close PER-51
```

The frontier is the set of tickets under a map that are unblocked and
unassigned:

```bash
rata issue list --parent PER-50 --unblocked --unassigned --json
```

## Reference

[`reference.md`](reference.md) lists every command and flag.
