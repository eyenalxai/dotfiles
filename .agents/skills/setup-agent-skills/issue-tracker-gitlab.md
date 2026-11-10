# Issue tracker: GitLab

Issues and specs for this repo live as GitLab issues. Use the [`glab`](https://gitlab.com/gitlab-org/cli) CLI for all operations.

## Conventions

- **Create an issue**: `glab issue create --title "..." --description "..."`. Use a heredoc for multi-line descriptions. Pass `--description -` to open an editor.
- **Read an issue**: `glab issue view <number> --comments`. Use `-F json` for machine-readable output.
- **List issues**: `glab issue list -O json` with `--label` filters.
- **Comment on an issue**: `glab issue note <number> --message "..."`. GitLab calls comments "notes".
- **Apply and remove labels**: `glab issue update <number> --label "..."` and `--unlabel "..."`. Separate multiple labels with commas or repeat the flag.
- **Close**: `glab issue close <number>`. `glab issue close` does not accept a closing comment, so post the explanation first with `glab issue note <number> --message "..."`, then close.
- **Merge requests**: GitLab calls PRs "merge requests". Use `glab mr create`, `glab mr view`, `glab mr note`, and the rest with the same shape as `gh pr ...`, using `mr` in place of `pr` and `note` or `--message` in place of `comment` or `--body`.

Infer the repo from `git remote -v`; `glab` does this automatically inside a clone.

## Merge requests as a triage surface

**MRs as a request surface: no.** _(Set to `yes` when this repo treats external merge requests as feature requests; `/triage` reads this flag.)_

When set to `yes`, MRs run through the same labels and states as issues, using the `glab mr` equivalents:

- **Read an MR**: `glab mr view <number> --comments`, and `glab mr diff <number>` for the diff.
- **List external MRs for triage**: `glab mr list -O json`, then keep only MRs whose author is not a project member or owner (a contributor's MR, not the owner's in-flight work).
- **Comment, label, and close**: `glab mr note`, `glab mr update --label` or `--unlabel`, `glab mr close`.

GitLab numbers issues and MRs separately, so `#42` is unambiguous once you know which surface the owner means.

## When a skill says "publish to the issue tracker"

Create a GitLab issue.

## When a skill says "fetch the relevant ticket"

Run `glab issue view <number> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is one issue with **child** issues as tickets. The person is the **owner**.

- **Map**: one issue labeled `wayfinder:map`, holding the Destination / Notes / Decisions so far / Not yet specified / Out of scope body. `glab issue create --label wayfinder:map`. On GitLab tiers with native epics, an epic can hold the map instead; a labeled issue works on every tier.
- **Child ticket**: an issue carrying `Part of #<map>` at the top of its description, linked to the map (`glab issue create --linked-issues <map> --link-type relates_to`), with labels `wayfinder:<type>` (`research`, `prototype`, `grilling`, `task`). A claimed ticket is assigned to the owner.
- **Blocking**: use GitLab's native blocking link, the canonical, UI-visible representation. Add it with the `/blocked_by #<n>` quick action, posted as a note (`glab issue note <child> --message "/blocked_by #<blocker>"`). Native blocking links are a Premium or Ultimate feature; on the free tier, or when unavailable, fall back to a `Blocked by: #<n>, #<n>` line at the top of the description. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's children with `glab api projects/:id/issues/<map>/links`, keep open issues that carry a `wayfinder:<type>` label, then drop any with an open blocker: a native `blocked_by` link to an open issue (`glab api projects/:id/issues/<child-iid>/links`), an open issue in the `Blocked by` line, or an assignee. The first in map order wins.
- **Claim**: `glab issue update <n> --assignee @me`, the session's first write.
- **Resolve**: `glab issue note <n> --message "<answer>"`, then `glab issue close <n>`, then append a context pointer (gist and link) to the map's Decisions so far.
