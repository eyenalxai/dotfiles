# Out-of-scope knowledge base

The `.out-of-scope/` directory in a repo stores persistent records of rejected feature requests. It serves two purposes:

1. **Institutional memory**: why a feature was rejected, so the reasoning is not lost when the issue closes.
2. **Deduplication**: when a new issue matches a prior rejection, the skill surfaces the previous decision instead of re-litigating it.

## Directory structure

```
.out-of-scope/
├── dark-mode.md
├── plugin-system.md
└── graphql-api.md
```

One file per **concept**, not per issue. Multiple issues requesting the same thing are grouped under one file.

## File format

Write the file as a short design document, not a database entry. Use paragraphs, code samples, and examples so the reasoning is clear to someone encountering it for the first time.

````markdown
# Dark Mode

This project does not support dark mode or user-facing theming.

## Why this is out of scope

The rendering pipeline assumes a single color palette defined in
`ThemeConfig`. Supporting multiple themes requires:

- A theme context provider wrapping the entire component tree
- Per-component theme-aware style resolution
- A persistence layer for user theme preferences

This is a significant architectural change that does not align with the
project's focus on content authoring. Theming is a concern for downstream
consumers who embed or redistribute the output.

```ts
// The current ThemeConfig interface is not designed for runtime switching:
interface ThemeConfig {
  colors: ColorPalette; // single palette, resolved at build time
  fonts: FontStack;
}
```

## Prior requests

- #42: "Add dark mode support"
- #87: "Night theme for accessibility"
- #134: "Dark theme option"
````

### Naming the file

Use a short, descriptive kebab-case name for the concept: `dark-mode.md`, `plugin-system.md`, `graphql-api.md`. The name must be recognizable enough that someone browsing the directory understands what was rejected without opening the file.

### Writing the reason

The reason must be substantive: state why, not "we do not want this". A durable reason names:

- Project scope or philosophy ("This project focuses on X; theming is a downstream concern")
- Technical constraints ("Supporting this requires Y, which conflicts with the Z architecture")
- Strategic decisions ("We chose A over B because...")

The reason must be durable. Avoid temporary circumstances ("we are too busy right now"); those are deferrals, not rejections.

## When to check `.out-of-scope/`

During triage (step 1: gather context), read all files in `.out-of-scope/`. When evaluating a new issue:

- Check whether the request matches an existing out-of-scope concept.
- Match by concept similarity, not keyword: "night theme" matches `dark-mode.md`.
- If there is a match, surface it to the owner: "This is similar to `.out-of-scope/dark-mode.md`. We rejected this before because [reason]. Do you still feel the same way?"

The owner may:

- **Confirm**: add the new issue to the existing file's "Prior requests" list, then close it.
- **Reconsider**: delete or update the out-of-scope file, and the issue proceeds through normal triage.
- **Disagree**: the issues are related but distinct; proceed with normal triage.

## When to write to `.out-of-scope/`

Write here only when an **enhancement**, not a bug, is *rejected* as `wontfix`. This applies to enhancement PRs exactly as it does to issues: record a rejected PR so the same request does not return as fresh code.

Do **not** write here when something is closed as `wontfix` because it is **already implemented**. That is a built feature, not a rejected one; recording it poisons the dedup checks with false rejections. The closing comment points to where the feature lives.

The flow:

1. The owner decides a feature request is out of scope.
2. Check for a matching `.out-of-scope/` file.
3. If one exists, append the new issue to the "Prior requests" list.
4. If none exists, create a file with the concept name, decision, reason, and first prior request.
5. Post a comment on the issue explaining the decision and naming the `.out-of-scope/` file.
6. Close the issue with the `wontfix` label.

## Updating or removing out-of-scope files

When the owner changes their mind about a previously rejected concept:

- Delete the `.out-of-scope/` file.
- Do not reopen old issues; they are historical records.
- The new issue that triggered the reconsideration proceeds through normal triage.
