# Agent brief examples

The examples below apply the principles in [AGENT-BRIEF.md](AGENT-BRIEF.md).

## Agent brief: bug

```markdown
## Agent Brief

**Category:** bug
**Summary:** Skill description truncation drops mid-word, producing broken output

**Current behavior:**
When a skill description exceeds 1024 characters, it is truncated at exactly
1024 characters regardless of word boundaries. This produces descriptions
that end mid-word (e.g. "Use when the user wants to confi").

**Desired behavior:**
Truncation breaks at the last word boundary before 1024 characters and
appends "..." to indicate truncation.

**Key interfaces:**
- The `SkillMetadata` type's `description` field: no type change, but the
  validation or processing logic that populates it respects word boundaries
- Any function that reads SKILL.md frontmatter and extracts the description

**Acceptance criteria:**
- [ ] Descriptions under 1024 chars are unchanged
- [ ] Descriptions over 1024 chars are truncated at the last word boundary
      before 1024 chars
- [ ] Truncated descriptions end with "..."
- [ ] The total length including "..." does not exceed 1024 chars

**Out of scope:**
- Changing the 1024 char limit itself
- Multi-line description support
```

## Agent brief: enhancement

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Add `.out-of-scope/` directory support for tracking rejected feature requests

**Current behavior:**
When a feature request is rejected, the issue is closed with a `wontfix` label
and a comment. No persistent record of the decision or reasoning exists.
Future similar requests require the owner to recall or search for the
prior discussion.

**Desired behavior:**
Rejected feature requests are documented in `.out-of-scope/<concept>.md`
files that capture the decision, reasoning, and links to all issues that
requested the feature. Triage checks these files for matches.

**Key interfaces:**
- Markdown file format in `.out-of-scope/`: each file has a
  `# Concept Name` heading, a `**Decision:**` line, a `**Reason:**` line,
  and a `**Prior requests:**` list with issue links
- The triage workflow reads all `.out-of-scope/*.md` files early
  and matches incoming issues against them by concept similarity

**Acceptance criteria:**
- [ ] Closing a feature as wontfix creates or updates a file in `.out-of-scope/`
- [ ] The file includes the decision, reasoning, and link to the closed issue
- [ ] If a matching `.out-of-scope/` file exists, the new issue is
      appended to its "Prior requests" list rather than creating a duplicate
- [ ] During triage, existing `.out-of-scope/` files are checked and surfaced
      when a new issue matches a prior rejection

**Out of scope:**
- Automated matching (a person confirms the match)
- Reopening previously rejected features
- Bug reports (only enhancement rejections go to `.out-of-scope/`)
```

## Agent brief: PR

For a PR, "Current behavior" describes the state of the diff, and the brief asks the agent to finish or fix it rather than build from scratch.

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Finish the contributor's `--json` output flag for `triage list`

**Current behavior:**
The PR adds a `--json` flag that serializes the issue list to JSON. The happy
path works and the diff matches the project's command structure. Two gaps
remain: errors print as plain text (not JSON), and the new flag has no test
coverage.

**Desired behavior:**
With `--json`, all output including errors is well-formed JSON on stdout,
and the command's exit codes stay unchanged. The existing readable output
is untouched when the flag is absent.

**Key interfaces:**
- The command's error path emits `{ "error": string }` under `--json`
  instead of the plain-text error
- Reuse the existing serializer the PR already added; do not introduce a second

**Acceptance criteria:**
- [ ] `triage list --json` emits valid JSON for both success and error cases
- [ ] Exit codes match the non-JSON command
- [ ] A test covers the `--json` success output and one error case
- [ ] Default (non-JSON) output is byte-for-byte unchanged

**Out of scope:**
- Adding `--json` to any other command
- Changing the JSON shape of the success payload the PR already defined
```

## Counterexample: a failing brief

```markdown
## Agent Brief

**Summary:** Fix the triage bug

**What to do:**
The triage thing is broken. Look at the main file and fix it.
The function around line 150 has the issue.

**Files to change:**
- src/triage/handler.ts (line 150)
- src/types.ts (line 42)
```

Why it fails:

- No category
- Vague description ("the triage thing is broken")
- References file paths and line numbers that go stale
- No acceptance criteria
- No scope boundaries
- No current or desired behavior
