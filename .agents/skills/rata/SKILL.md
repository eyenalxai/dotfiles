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

`link` writes `.rata.json`, so every later command knows the team. Use
`--create --name "<name>"` when the team does not exist yet. Without `--team`,
`link` asks for the workspace first, then the team. When the key exists in more
than one stored workspace, pass `--workspace <name>` to choose one.

## Read before you write

```bash
rata issue list --json                    # the default team's open issues
rata issue show ABC-42 --comments --json  # one issue with its comments
rata search "flaky test" --json
```

An issue reference is an identifier (`ABC-42`), a UUID, or a `linear.app` URL.
Every command supports `--json`; parse that, not the human output.

## Triage

Triage roles are labels. Apply one state and one category:

```bash
rata issue label add ABC-42 ready-for-agent
rata issue label remove ABC-42 needs-triage
```

States: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`,
`wontfix`. Categories: `bug`, `enhancement`.

Post the reasoning as a comment. `--body-file -` reads markdown from stdin, so
long bodies never touch the command line:

```bash
rata issue comment ABC-42 --body-file - <<'EOF'
## Triage

...
EOF
```

Close a `wontfix` with `rata issue close ABC-42 --comment "..."`.

## Publish tickets

```bash
rata issue create --title "Fix the flaky test" --label ready-for-agent --label bug --body-file - <<'EOF'
## What to build

...
EOF
```

`create` resolves the team and project from `.rata.json`, which `rata link`
writes. Override them with `--team` and `--project`.

Wire blocking edges as you publish. Linear has one `blocks` relation, so
`--blocked-by` records it in the direction you mean:

```bash
rata issue link ABC-43 --blocked-by ABC-42   # ABC-43 waits for ABC-42
```

## Specs as projects

A spec is an issue that belongs to a Linear project named after it. Create the
project first, then put the spec issue and its tickets in it:

```bash
rata project create --name "Spec: switch billing to Stripe"
rata issue create --title "Spec: switch billing to Stripe" --project "Spec: switch billing to Stripe" --body-file -
rata issue create --title "Add the Stripe client" --project "Spec: switch billing to Stripe" --label ready-for-agent --body-file -
rata issue list --project "Spec: switch billing to Stripe" --json
```

The project rolls up the progress of the set. Wayfinding maps stay issues with
child issues; projects group specs, not maps.

## Wayfinding

A map is an issue labelled `wayfinder:map`. Its tickets are children labelled
`wayfinder:<type>`, where type is `research`, `prototype`, `grilling`, or
`task`.

```bash
rata issue create --title "Map: switch billing to Stripe" --label wayfinder:map
rata issue create --parent ABC-50 --title "Research: Stripe webhook retries" --label wayfinder:research
```

Claim a ticket by assigning yourself. Resolve it with a comment, then close it:

```bash
rata issue assign me ABC-51
rata issue comment ABC-51 --body-file - <<'EOF'
## Answer

...
EOF
rata issue close ABC-51
```

The frontier is the set of tickets under a map that are unblocked and
unassigned:

```bash
rata issue list --parent ABC-50 --unblocked --unassigned --json
```

## Reference

[`reference.md`](reference.md) lists every command and flag.
