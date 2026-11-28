# rata command reference

Every command, flag and JSON shape. The `rata` skill covers the first command
and the loops. `docs/agents/issue-tracker.md` covers the repository rules.

## Invocation

`rata <command> [subcommand] [flags] [arguments]`

- `<ref>` is an issue identifier (`ABC-42`), a UUID, or a `linear.app` URL.
- The issue reads and every issue write, including `issue create`, accept
  `--format json|text` and `--select <paths>`. The admin commands accept
  `--format json|text`; the selectable admin reads also accept `--select`.
  `admin api` and `admin doctor` do not. JSON is the default when stdout is not a
  terminal.
- The old read forms (`issue show`, `issue view`, `issue status`, `next`, `why`)
  and the old read flags (`--json`, `--fields`, `--count`, `--ids-only`,
  `--include`) exit 2 with a `usage` error.
- `--body-file -` and `--comment-file -` read stdin. `--dry-run` previews.
- `--limit` is the page size: 50 by default, except `issue search` defaults to
  10; 250 at most. `--after` continues a page; `--all` drains every page. The
  repository config supplies the default team and project.
- Write help ends with an agent notes block: JSON, dry run, stdin and paging.

The command catalog below is generated from the registry by
`bun run docs:generate`. The sections after it explain the read and write
contracts.

<!-- rata:reference:begin -->
<!-- prettier-ignore-start -->
Generated from the command registry by `bun run docs:generate`. Do not edit this block by hand.

## Command index

| Command | Summary |
| --- | --- |
| `rata status` | Show the repository, workspace, team context and tracker document health |
| `rata issue` | Read and write Linear issues |
| `rata issue list` | List issues |
| `rata issue search` | Search issues by text |
| `rata issue create` | Create an issue |
| `rata issue publish` | Create a graph of issues and blocking edges from one document |
| `rata issue start` | Claim an issue and move it to a started state |
| `rata issue handoff` | Attach a pull request, apply fields, sections and one comment |
| `rata issue close` | Close an issue and move it to a completed state |
| `rata issue apply` | Apply one document to fields, labels, sections, a comment and relations |
| `rata issue relate` | Add or remove relation edges on an issue |
| `rata issue comment` | Post one comment on an issue |
| `rata triage` | Triage the queue and change roles. Not available yet. |
| `rata map` | Claim and resolve wayfinding work. Not available yet. |
| `rata admin` | Manage auth, the repository link, teams, projects, labels, the tracker doctor and the read-only API |
| `rata admin auth` | Manage Linear authentication |
| `rata admin auth login` | Store a Linear API key as a workspace profile |
| `rata admin auth status` | Show the selected profile, viewer and organization |
| `rata admin auth logout` | Remove one stored workspace profile |
| `rata admin link` | Bind this repository to a Linear team and set its timezone |
| `rata admin unlink` | Remove the stored link of this repository |
| `rata admin workspace` | Manage the stored Linear workspace profiles |
| `rata admin workspace list` | List the stored workspaces with their viewer and organization |
| `rata admin workspace use` | Set the default workspace profile |
| `rata admin config` | Show and change the issue defaults of this repository |
| `rata admin config show` | Show the issue defaults of this repository |
| `rata admin config set` | Set the issue defaults of this repository |
| `rata admin config unset` | Clear the issue defaults of this repository |
| `rata admin team` | Inspect, create and delete the teams in the workspace |
| `rata admin team list` | List the teams in the workspace |
| `rata admin team show` | Show the states, labels, members and priorities of a team |
| `rata admin team create` | Create a team with the machine timezone |
| `rata admin team delete` | Delete a team |
| `rata admin project` | Create, inspect, delete and restore the projects in the workspace |
| `rata admin project list` | List the projects in the workspace |
| `rata admin project create` | Create a project in one or more teams |
| `rata admin project delete` | Move a project to the trash, where Linear keeps it recoverable |
| `rata admin project restore` | Bring a project back from the trash, without a prompt |
| `rata admin label` | Create and inspect the labels of a team |
| `rata admin label list` | List the labels of a team |
| `rata admin label create` | Create a label |
| `rata admin label edit` | Update a label |
| `rata admin doctor` | Check the tracker document and repair its generated command block |
| `rata admin api` | Run a read-only GraphQL query against Linear |

**Global flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--format <json|text>` | `json|text` | no | Output format. JSON is the default when stdout is not a terminal |
| `--select <string>` | `string` | no | Comma-separated field paths for JSON output |

## Commands

### `rata status`

Show the repository, workspace, team context and tracker document health

```text
rata status [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--refresh` | `boolean` | no | Read the team context from Linear and update the cache |
| `--full` | `boolean` | no | Include the team timezone, members and priorities |

**Examples**

- `rata status`: Show the cached context in one call
- `rata status --format json`: Print the context for an agent
- `rata status --refresh`: Read the team context from Linear and update the cache
- `rata status --full`: Add the team timezone, members and priorities

### `rata issue`

Read and write Linear issues

```text
rata issue <subcommand> [flags] <ref...>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Issue references: identifiers, UUIDs, or linear.app URLs |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--summary` | `boolean` | no | Summary fields only: identity, state, priority, labels, URLs and timestamps |
| `--full` | `boolean` | no | Add relations and full child rows |
| `--comments` | `boolean` | no | Include the comments |

**Examples**

- `rata issue RAT-42`: Start a session with the body, sections, blockers, PRs, children and frontier
- `rata issue RAT-42 --comments --format json`: Add the comments to the working set
- `rata issue RAT-42 --summary`: Read the summary fields only
- `rata issue RAT-1 RAT-2 RAT-3`: Read a known set in one list request per page

#### `rata issue list`

List issues

```text
rata issue list [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--team <string>` | `string` | no | Filter by team key or id. Defaults to the team from `rata admin link` |
| `--state <string>` | `string` | no | Filter by workflow state name |
| `--state-type <triage|backlog|unstarted|started|completed|canceled|duplicate>` | `choice (triage|backlog|unstarted|started|completed|canceled|duplicate)` | no | Filter by workflow state type |
| `--priority <string>` | `string` | no | Priority: none, urgent, high, medium, low, or 0-4 |
| `--label <string>` | `string` | no | Filter by label name |
| `--assignee <string>` | `string` | no | Filter by assignee: `me` or a user id |
| `--project <string>` | `string` | no | Filter by project id or name |
| `--parent <string>` | `string` | no | Filter by parent issue reference |
| `--text <string>` | `string` | no | Filter by text in the title or the description |
| `--unblocked` | `boolean` | no | Keep only open issues with no open blocker |
| `--unassigned` | `boolean` | no | Keep only issues with no assignee |
| `--relations` | `boolean` | no | Add the six relation groups to each row |
| `--sort <priority>` | `choice (priority)` | no | Sort order: `priority` orders urgent first and none last; ties go to the oldest |
| `--limit <integer>` | `integer` | no | Page size, at most 250 |
| `--after <string>` | `string` | no | Continue after this cursor |
| `--all` | `boolean` | no | Drain every page; --limit stays the page size |

**Examples**

- `rata issue list --label ready-for-agent --format json`: List the ready tickets of one team
- `rata issue list --parent RAT-1 --unblocked --unassigned --sort priority`: List the frontier of a map
- `rata issue list --limit 100 --after <cursor>`: Read the next page from the endCursor of the previous call

#### `rata issue search`

Search issues by text

```text
rata issue search [flags] <text>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<text>` | `string` | yes | Text to search for |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--team <string>` | `string` | no | Filter by team key or id. Defaults to the team from `rata admin link` |
| `--limit <integer>` | `integer` | no | Page size, at most 250. Default: 10 |
| `--after <string>` | `string` | no | Continue after this cursor |
| `--all` | `boolean` | no | Drain every page; --limit stays the page size |

**Examples**

- `rata issue search "rate limit"`: Search the linked team and return ten summary rows
- `rata issue search "rate limit" --all --format json`: Drain every page of results

#### `rata issue create`

Create an issue

```text
rata issue create [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--title <string>` | `string` | yes | Issue title |
| `--body-file <string>` | `string` | no | Read the body from a file. Use - for standard input |
| `--team <string>` | `string` | no | Team key or id. Defaults to the team from `rata admin link` |
| `--label <string>` | `string` | no | Label name. Repeat for more labels |
| `--parent <string>` | `string` | no | Parent issue reference |
| `--project <string>` | `string` | no | Project id or name |
| `--state <string>` | `string` | no | Workflow state name |
| `--assignee <string>` | `string` | no | Assignee: `me`, a user id, or `none` |
| `--priority <string>` | `string` | no | Priority: none, urgent, high, medium, low, or 0-4 |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata issue create --title "Fix login" --team RAT --label ready-for-agent`: Create an issue with a label
- `echo "The body" | rata issue create --title "Fix login" --team RAT --body-file -`: Read the body from standard input
- `rata issue create --title "Fix login" --team RAT --dry-run`: Print the plan and write nothing

#### `rata issue publish`

Create a graph of issues and blocking edges from one document

```text
rata issue publish [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--file <string>` | `string` | yes | Read the publish document from a file. Use - for standard input |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata issue publish --file graph.json`: Create a parent, its children and their blocking edges
- `rata issue publish --file - --dry-run < graph.json`: Print the node and edge plan without writing
- `rata issue publish --file graph.json --dry-run`: Show what a retry would reuse, create or link

#### `rata issue start`

Claim an issue and move it to a started state

```text
rata issue start [flags] <ref>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Issue reference: an identifier, a UUID, or a linear.app URL |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--state <string>` | `string` | no | Workflow state name. Defaults to the first started state |
| `--take` | `boolean` | no | Reassign an issue held by another user |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata issue start RAT-42`: Claim an unassigned issue and start it
- `rata issue start RAT-42 --take`: Take an issue from another user and start it
- `rata issue start RAT-42 --state 'In Review'`: Move the issue to a named state

#### `rata issue handoff`

Attach a pull request, apply fields, sections and one comment

```text
rata issue handoff [flags] <ref>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Issue reference: an identifier, a UUID, or a linear.app URL |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--file <string>` | `string` | yes | Read the handoff document from a file. Use - for standard input |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata issue handoff RAT-42 --file - < handoff.json`: Attach the PR, move the state, append a section and post one comment
- `rata issue handoff RAT-42 --file handoff.json --dry-run`: Print the plan and write nothing

#### `rata issue close`

Close an issue and move it to a completed state

```text
rata issue close [flags] <ref>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Issue reference: an identifier, a UUID, or a linear.app URL |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--comment-file <string>` | `string` | no | Read the comment from a file. Use - for standard input |
| `--force` | `boolean` | no | Close even when the issue has open children |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata issue close RAT-42`: Close an issue
- `echo 'Done in PR #12' | rata issue close RAT-42 --comment-file -`: Close an issue and post one comment
- `rata issue close RAT-42 --force`: Close an issue that still has open children

#### `rata issue apply`

Apply one document to fields, labels, sections, a comment and relations

```text
rata issue apply [flags] <ref>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Issue reference: an identifier, a UUID, or a linear.app URL |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--file <string>` | `string` | yes | Read the apply document from a file. Use - for standard input |
| `--if-unchanged <string>` | `string` | no | Fail with a conflict when the issue snapshot changed |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata issue apply RAT-42 --file - < update.json`: Apply fields, labels, sections, a comment and relations in one call
- `rata issue apply RAT-42 --file update.json --dry-run`: Print the plan and write nothing
- `rata issue apply RAT-42 --file update.json --if-unchanged <snapshot>`: Apply only when the issue still matches the snapshot

#### `rata issue relate`

Add or remove relation edges on an issue

```text
rata issue relate [flags] <ref>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Issue reference: an identifier, a UUID, or a linear.app URL |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--blocks <string>` | `string` | no | Issue that waits for this one. Repeat for more |
| `--blocked-by <string>` | `string` | no | Issue that this one waits for. Repeat for more |
| `--related <string>` | `string` | no | Related issue. Repeat for more |
| `--duplicate <string>` | `string` | no | Issue that this one duplicates. Repeat for more |
| `--remove` | `boolean` | no | Remove the named relation edges instead of adding them |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata issue relate RAT-42 --blocked-by RAT-41`: Make RAT-42 wait for RAT-41
- `rata issue relate RAT-42 --blocks RAT-41 RAT-40`: Make two issues wait for RAT-42
- `rata issue relate RAT-42 --related RAT-41 --remove`: Remove the relation from both issues

#### `rata issue comment`

Post one comment on an issue

```text
rata issue comment [flags] <ref>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Issue reference: an identifier, a UUID, or a linear.app URL |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--body-file <string>` | `string` | yes | Read the comment from a file. Use - for standard input |
| `--dedupe-key <string>` | `string` | no | Stable key that makes a retry return skipped. Required |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `printf 'Started work.' | rata issue comment RAT-42 --body-file -`: Post a comment from standard input
- `rata issue comment RAT-42 --body-file note.md --dedupe-key handoff-42`: Post a comment that a retry cannot duplicate

### `rata triage`

Triage the queue and change roles. Not available yet.

```text
rata triage
```


### `rata map`

Claim and resolve wayfinding work. Not available yet.

```text
rata map
```


### `rata admin`

Manage auth, the repository link, teams, projects, labels, the tracker doctor and the read-only API

```text
rata admin <subcommand>
```


#### `rata admin auth`

Manage Linear authentication

```text
rata admin auth <subcommand>
```


##### `rata admin auth login`

Store a Linear API key as a workspace profile

```text
rata admin auth login [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--with-token` | `boolean` | no | Read the API key from standard input |
| `--workspace <string>` | `string` | no | Workspace profile name |

**Examples**

- `pbpaste | rata admin auth login --with-token`: Store the API key from the clipboard as the default profile
- `pbpaste | rata admin auth login --with-token --workspace work`: Store the API key as the work profile

##### `rata admin auth status`

Show the selected profile, viewer and organization

```text
rata admin auth status [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--workspace <string>` | `string` | no | Workspace profile name |

##### `rata admin auth logout`

Remove one stored workspace profile

```text
rata admin auth logout [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--workspace <string>` | `string` | no | Workspace profile name |

#### `rata admin link`

Bind this repository to a Linear team and set its timezone

```text
rata admin link [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--team <string>` | `string` | no | Team key or id. Without --workspace, link searches every stored workspace |
| `--project <string>` | `string` | no | Default project name or id for this repository |
| `--workspace <string>` | `string` | no | Workspace profile to link in. Skips the workspace prompt |
| `--create` | `boolean` | no | Create the team when it does not exist |
| `--name <string>` | `string` | no | Team name, used with --create |

**Examples**

- `rata admin link`: Choose the workspace and the team interactively
- `rata admin link --team RAT --project rata`: Link the repository to a team found in the stored workspaces
- `rata admin link --team SCR --create --name "Scratch"`: Create the team, then link the repository
- `rata admin link --workspace work --team RAT`: Link to a team in the work workspace

#### `rata admin unlink`

Remove the stored link of this repository

```text
rata admin unlink
```


**Examples**

- `rata admin unlink`: Remove the stored team, project and workspace of this repository
- `rata admin unlink --format json`: Print the removed link as JSON

#### `rata admin workspace`

Manage the stored Linear workspace profiles

```text
rata admin workspace <subcommand>
```


##### `rata admin workspace list`

List the stored workspaces with their viewer and organization

```text
rata admin workspace list
```


##### `rata admin workspace use`

Set the default workspace profile

```text
rata admin workspace use <name>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<name>` | `string` | yes | Workspace profile name |

**Examples**

- `rata admin workspace use work`: Use the work profile when no repository selects one

#### `rata admin config`

Show and change the issue defaults of this repository

```text
rata admin config <subcommand>
```


##### `rata admin config show`

Show the issue defaults of this repository

```text
rata admin config show
```


**Examples**

- `rata admin config show`: Show the defaults of this repository
- `rata admin config show --select assignee,labels`: Read the defaults for an agent

##### `rata admin config set`

Set the issue defaults of this repository

```text
rata admin config set [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--assignee <string>` | `string` | no | Default assignee: `me`, a user id, or `none` |
| `--label <string>` | `string` | no | Default label name. Repeat to replace the list |
| `--priority <string>` | `string` | no | Default priority: none, urgent, high, medium, low, or 0-4 |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata admin config set --assignee me --label enhancement --priority medium`: Apply these values to every new issue
- `rata admin config set --priority high`: Change only the default priority

##### `rata admin config unset`

Clear the issue defaults of this repository

```text
rata admin config unset [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--assignee` | `boolean` | no | Clear the default assignee |
| `--label` | `boolean` | no | Clear the default labels |
| `--priority` | `boolean` | no | Clear the default priority |
| `--dry-run` | `boolean` | no | Resolve the targets and print the actions without writing |

**Examples**

- `rata admin config unset --label`: Drop the default labels

#### `rata admin team`

Inspect, create and delete the teams in the workspace

```text
rata admin team <subcommand>
```


##### `rata admin team list`

List the teams in the workspace

```text
rata admin team list [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--limit <integer>` | `integer` | no | Page size, at most 250 |
| `--after <string>` | `string` | no | Continue after this cursor |
| `--all` | `boolean` | no | Drain every page; --limit stays the page size |

##### `rata admin team show`

Show the states, labels, members and priorities of a team

```text
rata admin team show [<ref>]
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | no | Team key or id. Default: the linked team |

**Examples**

- `rata admin team show RAT`: Show the team named by its key
- `rata admin team show --format json`: Show the linked team for an agent

##### `rata admin team create`

Create a team with the machine timezone

```text
rata admin team create [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--name <string>` | `string` | yes | Team name |
| `--key <string>` | `string` | no | Team key, for example RAT |
| `--description <string>` | `string` | no | Team description |
| `--copy-settings-from <string>` | `string` | no | Team key or id to copy settings from |

**Examples**

- `rata admin team create --name "Scratch" --key SCR`: Create a team with an explicit key
- `rata admin team create --name "Scratch" --copy-settings-from RAT`: Create a team that copies another team's settings

##### `rata admin team delete`

Delete a team

```text
rata admin team delete [flags] <key>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<key>` | `string` | yes | Team key or id |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--yes` | `boolean` | no | Skip the confirmation prompt |

**Examples**

- `rata admin team delete SCR`: Delete a team after a confirmation prompt
- `rata admin team delete SCR --yes`: Delete a team without a prompt

#### `rata admin project`

Create, inspect, delete and restore the projects in the workspace

```text
rata admin project <subcommand>
```


##### `rata admin project list`

List the projects in the workspace

```text
rata admin project list [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--team <string>` | `string` | no | Filter by team key or id. Defaults to the team from `rata admin link` |
| `--limit <integer>` | `integer` | no | Page size, at most 250 |
| `--after <string>` | `string` | no | Continue after this cursor |
| `--all` | `boolean` | no | Drain every page; --limit stays the page size |
| `--include-archived` | `boolean` | no | Include trashed and archived projects |

##### `rata admin project create`

Create a project in one or more teams

```text
rata admin project create [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--name <string>` | `string` | yes | Project name |
| `--team <string>` | `string` | no | Team key or id. Repeat for more teams. Defaults to the team from `rata admin link` |
| `--description <string>` | `string` | no | Project description |

**Examples**

- `rata admin project create --name "Spec: login" --team RAT`: Create a project in one team
- `rata admin project create --name "Spec: login" --team RAT --team OPS`: Create a project in several teams

##### `rata admin project delete`

Move a project to the trash, where Linear keeps it recoverable

```text
rata admin project delete [flags] <ref>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Project name or UUID |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--yes` | `boolean` | no | Skip the confirmation prompt |

**Examples**

- `rata admin project delete "Login revamp"`: Move a project to the trash after a confirmation prompt
- `rata admin project delete "Login revamp" --yes`: Move a project to the trash without a prompt

##### `rata admin project restore`

Bring a project back from the trash, without a prompt

```text
rata admin project restore <ref>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<ref>` | `string` | yes | Project name or UUID |

**Examples**

- `rata admin project restore "Login revamp"`: Bring a project back from the trash by name
- `rata admin project restore 0f8fad5b-d9cb-469f-a165-70867728950e`: Bring a project back from the trash by UUID

#### `rata admin label`

Create and inspect the labels of a team

```text
rata admin label <subcommand>
```


##### `rata admin label list`

List the labels of a team

```text
rata admin label list [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--team <string>` | `string` | no | Team key or id. Defaults to the team from `rata admin link` |
| `--limit <integer>` | `integer` | no | Page size, at most 250 |
| `--after <string>` | `string` | no | Continue after this cursor |
| `--all` | `boolean` | no | Drain every page; --limit stays the page size |

##### `rata admin label create`

Create a label

```text
rata admin label create [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--name <string>` | `string` | yes | Label name |
| `--color <string>` | `string` | no | Label color: 6 hex digits, with or without #. For example #EB5757 |
| `--team <string>` | `string` | no | Team key or id. Defaults to the team from `rata admin link` |
| `--if-not-exists` | `boolean` | no | Return the existing label instead of failing on a duplicate name |

**Examples**

- `rata admin label create --team RAT --name bug --color "#EB5757"`: Create a label with a color
- `rata admin label create --team RAT --name bug`: Create a label and let Linear pick the color
- `rata admin label create --team RAT --name bug --if-not-exists`: Return the existing label when the name is taken

##### `rata admin label edit`

Update a label

```text
rata admin label edit [flags] <label>
```

**Arguments**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `<label>` | `string` | yes | Label reference: a name or a UUID |

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--name <string>` | `string` | no | New label name |
| `--color <string>` | `string` | no | Label color: 6 hex digits, with or without #. For example #EB5757 |
| `--team <string>` | `string` | no | Team key or id. Defaults to the team from `rata admin link` |

**Examples**

- `rata admin label edit bug --color "#0F783C"`: Change the color of a label
- `rata admin label edit bug --name regression --team RAT`: Rename a label

#### `rata admin doctor`

Check the tracker document and repair its generated command block

```text
rata admin doctor [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--write` | `boolean` | no | Rewrite the generated command block in the tracker document |

**Examples**

- `rata admin doctor`: Report stale command forms in the tracker document
- `rata admin doctor --write`: Rewrite the generated command block

#### `rata admin api`

Run a read-only GraphQL query against Linear

```text
rata admin api [flags]
```

**Flags**

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `--query <string>` | `string` | no | GraphQL query. Reads standard input when absent |

**Examples**

- `rata admin api --query "query Viewer { viewer { id name } }"`: Read the viewer directly from Linear
- `printf '%s' "query Teams { teams { nodes { key name } } }" | rata admin api`: Read a query from standard input

<!-- prettier-ignore-end -->
<!-- rata:reference:end -->

## JSON and errors

A single-resource read prints that object. A list prints `{ <plural>, pageInfo }`.
A context document keeps named sections. A write prints its result.

With JSON output, a failure writes
`{ "error": { "code", "message", "hint" } }` to stderr; `hint` is a string or
`null`; `RATA_DEBUG=1` adds `details`. Human mode prints `error:` and `hint:`.

Codes: `0` success, `1` internal, `2` usage or validation, `3` not found,
`4` conflict, `5` auth, `6` retryable. A parse error writes the normal error
object with code `usage`; help prints only for `--help`. A partial apply writes
one resource document with `result.status: "failed"`, the applied actions, the
failed action and `result.error`, and exits with the failed action's code.

## Setup

`admin auth login --with-token [--workspace <name>]` saves a key from stdin;
`admin auth status`, `admin auth logout`, `admin workspace list` and
`admin workspace use <name>` manage it; `admin unlink` removes the link and
defaults. `status [--refresh]` prints the repo, workspace, key source, team,
project, defaults, states, labels, triage map, cache age, document health, viewer
and org. The team detail is cached in SQLite for seven days. A warm `status`
makes no Linear request; `--refresh` reads Linear and replaces the cache. `admin
link [--team] [--project] [--workspace] [--create --name]` links the repo and
stores the team UUID; without `--team` it prompts and sets the team timezone.
`admin config show`, `admin config set` and `admin config unset` manage the issue
defaults; `--label` replaces the list. `admin doctor` checks the generated
command block in the tracker document; `--write` repairs it. `admin api --query`
or a query on stdin runs one read-only GraphQL request and returns its `data`.

The key resolves as `LINEAR_API_KEY`, the repository `workspace`, then
`default`. A stored team resolves by UUID, key, then name. A stale UUID or key
that resolves is repaired with a warning; `status` keeps the warning. A warm
cache can serve the stored UUID for up to seven days; `--refresh` revalidates
it. A team that no longer exists fails a read with `not_found` and the repair
hint; `status` exits 0 with `team`, `defaults` and `cache` at `null` and
`states` and `labels` empty. The triage map and the document health stay. A
legacy `.rata.json` is imported and removed on first use; a failed remove warns.

`status` carries `states` and `labels` from the cache, the `triage` map parsed
from `docs/agents/triage-labels.md`, `cache.ageSeconds`, and `docs.tracker` and
`docs.triage` health. The triage document must declare the canonical label
header; a reordered table parses by header name. A headerless or incomplete
document is an unhealthy `docs.triage` with a warning; `status` still prints the
rest. An unknown state or label refreshes the context once, then fails
`not_found` with the valid names.

A command resolves the repository context once: root, profile, team identity
and cached detail, states, labels, defaults and the stale-link warning. The
viewer is lazy. `--assignee me` loads the cached viewer only for that read; a
read without it does not.

Writes follow the issue. A linked repository writes against the linked team.
Without a link, state and label writes fall back to the issue's team. A single
write on an issue in another team uses that issue's team, even when the
repository is linked. A write that repairs a stale link prints the warning, as
`list` and `search` do. Bulk label writes resolve each child team's labels.

## Teams, projects and labels

`admin team list [--limit] [--after] [--all]`; `admin team show [<ref>]` gives
states, labels, members and priorities; `admin team create --name <name>
[--key]`; `admin team delete <key> [--yes]`. `admin project list [--team]
[--include-archived] [--limit] [--after] [--all]`; `admin project create --name
<name> [--team]`; `admin project delete <ref> [--yes]`; `admin project restore
<ref>`. `admin label list [--team] [--limit] [--after] [--all]`; `admin label
create --name <name> [--color] [--team] [--if-not-exists]`; `admin label edit
<ref> [--name] [--color] [--team]`.

## Issues

### Read shapes

| Command                                                     | JSON                                                                                                                                             |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `issue <ref>`                                               | The working set: summary fields, `description`, `sections`, `blocked`, `blockedBy`, `prs`, `children`, `frontier`, `nextChild`, `comments: null` |
| `issue <ref> --summary`                                     | The summary fields: `id`, `identifier`, `title`, `state`, `priority`, `labels`, `assignee`, `project`, `parent`, `url`, `createdAt`, `updatedAt` |
| `issue <ref> --full`                                        | The working set plus `relations` and full child rows                                                                                             |
| `issue <ref> <ref> ...`                                     | `{ items, pageInfo }`; one working set per ref, one list request per page                                                                        |
| `admin team show [<ref>]`                                   | The team object                                                                                                                                  |
| `issue list`                                                | `{ issues, pageInfo }`; `--relations` adds the six relation groups                                                                               |
| `issue search`                                              | `{ issues, pageInfo }`; ten summary rows by default, no description                                                                              |
| `admin team list`, `admin project list`, `admin label list` | `{ <plural>, pageInfo }`                                                                                                                         |
| `status`                                                    | Named sections: `repository`, `workspace`, `viewer`, `team`, `project`, `defaults`, `states`, `labels`, `triage`, `cache`, `docs`, `warning`     |
| `admin config show`                                         | `{ defaults }`                                                                                                                                   |
| `admin auth status`                                         | `{ authenticated, source, profile, storePath, viewer }`                                                                                          |
| `admin link`                                                | `{ team, project, workspace, timezone }`                                                                                                         |
| `admin doctor`                                              | `{ document, healthy, stale, block, written }`                                                                                                   |
| `admin api`                                                 | `{ data }` with the raw GraphQL response                                                                                                         |

The working set carries the summary fields, the parsed `sections`, `blocked` and
`blockedBy`, the Linear `github` attachments as `prs` (`checks` and `mergeCommit`
are `null`, each PR says `source: "linear"`), lean `children` with `blocked` and
`blockedBy`, `frontier` (open, unblocked, unassigned children), `nextChild` (the
first frontier row) and `comments: null`. `--comments` fills the comments.
`--summary` returns the summary fields only. `--full` adds the six `relations`
groups and full child rows; the summary fields are already in the default
working set. `issue list` and `issue search` rows are summaries with `url`,
timestamps and labels; search rows have no description.

### Field selection

`--select` selects dotted paths from an issue read. It validates the declared
shape of the active mode (summary, working or full) before the read, so an
unknown path is `validation` even on an empty list or a null object; `details`
carries `path` and `validPaths`. It starts at the resource for one ref, at each
row for a list, and at each item for many refs.

A path through a null object returns `null`. An array is selectable whole. A path
may cross an array: a final array segment returns the array; a later segment maps
each element; a scalar leaf returns an array of scalars (`labels.name` ->
`["bug"]`); an object leaf returns an array of objects (`children.state` ->
`[{ "state": ... }]`); paths that cross the same array merge. A path through an
array of scalars is `validation`; an empty array returns `[]`. A list keeps
`pageInfo`.

### `issue <ref>` flags

`--comments` adds comments; the default read returns `comments: null`.
`--summary` returns the summary fields only and rejects `--comments`.
`--full` adds relations and full child rows. `--summary` and `--full` are
mutually exclusive. Many refs print `{ "items", "pageInfo" }`; each page of refs
is one list request, not one detail read per ref. Under Linear's 10,000-point
query cap, a page holds up to 250 refs in summary mode, 5 in working mode and 3
in full mode. Every requested connection is drained: children, relations, labels,
attachments and comments each fetch their remaining pages in one batched request
per connection page.

### `issue list` flags

`--team`, `--state`, `--state-type`, `--priority`, `--label`, `--assignee`,
`--project`, `--parent`, `--text`, `--unblocked` and `--unassigned` filter;
`--limit`, `--after` and `--all` page. `--relations` adds the six relation groups
to every row with one request per page.

On an empty page, `--state`, `--label` and `--project` are checked for
existence. An unknown name is `not_found` with the valid names; a valid name
with no matches stays empty. `--assignee` accepts `me` or a user UUID; a
malformed value is `validation`, an unknown UUID is `not_found`.

`--sort priority` orders urgent first and none last; ties go to the oldest.
`--limit` stays the page size and `--after` continues the sorted result.

### `issue search` flags

`issue search <text> [--team] [--limit] [--after] [--all]` returns ten summary
rows by default. `--limit` changes the page size, `--after` continues from a
cursor and `--all` drains. It keeps relevance order. It does not return
descriptions.

### Paging

Every list prints one page: `--limit` is the page size, `--after` continues from
`pageInfo.endCursor`, and `--all` drains with `pageInfo`
`{ "hasNextPage": false, "endCursor": null }`. Keep the filters and order fixed;
a cursor is bound to its query.

## Issue writes

Every write uses the same plan and result contract. `issue apply` takes the
general document; `issue publish` creates a graph; `issue start`, `issue handoff`
and `issue close` are the lifecycle forms. `issue apply <ref> --file -` reads
one JSON document:

```json
{
  "state": "In Progress",
  "assignee": "me",
  "priority": "high",
  "labels": { "add": ["ready-for-agent"], "remove": ["needs-triage"] },
  "sections": [
    { "heading": "Handoff log", "mode": "append", "content": "PR #42 is open." },
    { "heading": "Flow", "mode": "replace", "content": "..." }
  ],
  "comment": { "body": "Started work.", "dedupeKey": "start-42" },
  "relations": { "blockedBy": ["RAT-41"] }
}
```

The fields are `title`, `state`, `assignee`, `priority`, `project` and `parent`.
`assignee`, `project` and `parent` accept `null` to clear them. The engine plans
every action before it writes. It touches only named fields and objects. A bad
state, label or heading fails before the first write. A partial failure returns
the applied actions, `failed` and `error`; the exit code is the failed action's.

`--dry-run` returns the same `{ issue, result }` with `dryRun: true` and writes
nothing. `--if-unchanged <snapshot>` checks `result.snapshot` once before the
first mutation; a mismatch exits 4. A no-op returns `status: "skipped"`.

Sections: `replace` requires the heading and fails with `not_found` when it is
missing; `append` adds to an existing section or creates a missing `## heading`
at the end. A heading that appears more than once is a `conflict`.

Comment: `issue apply` requires `comment.dedupeKey`. The key is scoped to the
issue; a retry returns `skipped`. `issue comment <ref> --body-file -` posts one
comment and requires `--dedupe-key`.

Relations are a set. An existing edge is `skipped`. Omit a group to leave it
alone. `issue relate <ref> (--blocks|--blocked-by|--related|--duplicate)
<target>...` adds one-off edges; `--remove` removes them.

### Publish

`issue publish --file - [--dry-run]` reads one JSON document with `team`,
`parent`, `defaults` and `nodes`. Each node requires `key`, `kind` and `title`;
`body`, `priority`, `labels`, `assignee`, `state`, `parent` and `blockedBy` are
optional. A parent or a blocker may name a node key or an existing issue
reference. The engine orders the nodes, derives a stable client UUID from the
parent and key (the team scopes a top-level node), reads the existing ids before
it creates, and creates up to 50 nodes per `issueBatchCreate`. It adds only the
missing blocking edges. A cycle or an unknown key fails before the first write.
A retry reuses the nodes and skips the edges that already exist. `kind` is
recorded on the node and in the result; in this slice it does not set labels or
assignees. The result is `{ nodes, edges, result }`; `--dry-run` writes nothing.

### Lifecycle

`issue start <ref> [--state <name>] [--take] [--dry-run]` claims an unassigned
issue, skips a claim the viewer already holds, and exits 4 with the holder when
another user holds it. `--take` reassigns. It moves to the first `started` state
or to `--state`. A retry is `skipped`.

`issue handoff <ref> --file -` reads an apply document plus `pr`, the pull
request URL. It attaches the PR, applies the fields, sections and one deduped
comment, and a retry is `skipped`.

`issue close <ref> [--comment-file -] [--force] [--dry-run]` refuses open
children without `--force` and names them. It moves the issue to the first
`completed` state and skips an already closed issue. The comment comes from the
file; a new comment posts once, and the same comment is `skipped` on a retry. The
old `--comment` string flag is gone.

The old write forms (`issue update`, `issue label`, `issue section`,
`issue assign`, `issue unassign`, `issue reopen`, `issue link`, `issue unlink`
and `issue comment create/update/delete`) exit 2 with a `usage` error.

## Idempotency

A write that finds the desired state in place exits 0 and reports `skipped`;
this covers `issue apply`, `issue publish`, `issue start`, `issue handoff`,
`issue close`, `issue relate`, `issue comment`, `admin link` and `admin unlink`.
A closed issue is skipped by `issue close`; a new comment posts once, and the
same comment is skipped. A `canceled` or `duplicate` issue counts as closed.
`issue create` always creates a new object. `admin label create` fails on a
duplicate name with `conflict` unless `--if-not-exists` returns it with
`created: false`.

## Executable hints

A known wrong form fails before any request, keeps the JSON error shape, and
prints one hint that names the command to run. Old command forms return `usage`;
a removed flag can return `validation`. A supplied body, label or relation value
stays in the hint, shell-quoted when needed.

| Wrong form                                 | Hint                                                                         |
| ------------------------------------------ | ---------------------------------------------------------------------------- |
| `issue show <ref>`                         | `rata issue <ref>`                                                           |
| `issue status <ref>`                       | `rata issue <ref>`                                                           |
| `issue comment create <ref>`               | `rata issue comment <ref> --body-file - --dedupe-key <key>`                  |
| `issue update <ref> --label <label...>`    | `rata issue apply <ref> --file -` with `labels.add`                          |
| `issue create --blocked-by <ref>`          | `Create the issue, then run rata issue relate <new-ref> --blocked-by <ref>.` |
| `issue update <ref> --blocked-by <ref>`    | `rata issue relate <ref> --blocked-by <ref>`                                 |
| `issue link <ref>` without a relation flag | `rata issue relate <ref> --blocked-by <blocker>`                             |
| an issue read with `--fields`              | `Use --format json; --select replaces --fields.`                             |
| a write with `--fields`                    | `Use --format json; --select replaces --fields.`                             |
