# op-completions.nu
# Custom completions for 1Password CLI (op) in Nushell
# nu-version: 0.115.1

# ==============================================================================
# Helper Completers
# ==============================================================================

# Complete configured 1Password accounts (email, sign-in address, user ID, account ID)
def "nu-complete op accounts" [] {
  try {
    let res = (do { ^op account list --format json } | complete)
    if $res.exit_code != 0 or ($res.stdout | is-empty) { return [] }
    let accts = ($res.stdout | from json)
    $accts | each { |a|
      [
        { value: $a.email, description: $"Account ($a.email) on ($a.url)" }
        { value: $a.url, description: $"Account ($a.email) \(($a.user_uuid)\)" }
        { value: $a.user_uuid, description: $"User UUID for ($a.email)" }
        { value: $a.account_uuid, description: $"Account UUID for ($a.email)" }
      ]
    } | flatten | uniq-by value
  } catch {
    []
  }
}

# ==============================================================================
# Dynamic (cached) data completers
# ==============================================================================

# Directory used to cache 1Password CLI data for completions
def "nu-complete op cache-dir" [] {
  let base = ($env.XDG_CACHE_HOME? | default ($env.HOME | path join ".cache"))
  $base | path join "op-completions"
}

# Restrict permissions on cached 1Password data (best effort)
def "nu-complete op cache-chmod" [path: string, mode: string] {
  try { ^chmod $mode $path | ignore } catch {}
}

# Fetch JSON from the op CLI and store it in the completion cache (runs in a background job)
def "nu-complete op cache-refresh" [name: string, args: list<string>, timeout: int] {
  let dir = (nu-complete op cache-dir)
  let file = ($dir | path join $"($name).json")
  try {
    let res = (do { ^timeout $timeout op ...$args } | complete)
    if $res.exit_code == 0 and ($res.stdout | is-not-empty) {
      if not ($dir | path exists) { mkdir $dir }
      nu-complete op cache-chmod $dir 700
      let tmp = ($dir | path join $"($name).tmp.json")
      $res.stdout | from json | to json | save -f $tmp
      mv -f $tmp $file
      nu-complete op cache-chmod $file 600
    }
  }
}

# Return cached JSON produced by an op command, refreshing it in the background when stale
def "nu-complete op cached-json" [
  name: string        # Cache file name
  args: list<string>  # op arguments that produce JSON output
  ttl: duration       # How long cached data is considered fresh
] {
  let dir = (nu-complete op cache-dir)
  let file = ($dir | path join $"($name).json")
  let lock = ($dir | path join $"($name).lock")
  if not ($dir | path exists) { mkdir $dir }
  nu-complete op cache-chmod $dir 700

  let exists = ($file | path exists)
  let fresh = if $exists {
    try { ((date now) - (ls -D $file | get 0.modified)) < $ttl } catch { false }
  } else {
    false
  }
  if $fresh {
    return (try { open $file } catch { [] })
  }

  if not $exists {
    # First run: wait briefly so completions are useful immediately
    let res = (do { ^timeout 6 op ...$args } | complete)
    if $res.exit_code == 0 and ($res.stdout | is-not-empty) {
      try {
        let data = ($res.stdout | from json)
        let tmp = ($dir | path join $"($name).tmp.json")
        $data | to json | save -f $tmp
        mv -f $tmp $file
        nu-complete op cache-chmod $file 600
        return $data
      } catch {}
    }
  }

  # Serve stale data and refresh the cache in the background
  let lock_fresh = if ($lock | path exists) {
    try { ((date now) - (ls -D $lock | get 0.modified)) < 1min } catch { false }
  } else {
    false
  }
  if not $lock_fresh {
    touch $lock
    job spawn {|| nu-complete op cache-refresh $name $args 30 } | ignore
  }

  try { open $file } catch { [] }
}

# Extract the vault name or ID given to --vault (or --current-vault) on the command line
def "nu-complete op vault-from-context" [context: string] {
  let matches = ($context | parse -r "--(?:current-)?vault(?:=|\\s+)(?:\"(?<dq>[^\"]*)\"|'(?<sq>[^']*)'|(?<bare>\\S+))")
  if ($matches | is-empty) { return "" }
  let m = ($matches | last)
  if ((($m.dq? | default "") | is-not-empty)) { return $m.dq }
  if ((($m.sq? | default "") | is-not-empty)) { return $m.sq }
  ($m.bare? | default "")
}

# Complete 1Password item names and IDs, filtered by --vault when present
def "nu-complete op items" [context: string] {
  let data = (nu-complete op cached-json "items" [item list --format json] 5min)
  let vault = (nu-complete op vault-from-context $context)
  let items = if ($vault | is-empty) {
    $data
  } else {
    $data | where { |i| $i.vault.name == $vault or $i.vault.id == $vault }
  }
  let titles = ($items | each { |i|
    let info = ($i.additional_information? | default "")
    let extra = if ($info | is-not-empty) and ($info != "—") { $" • ($info)" } else { "" }
    { value: $i.title, description: $"($i.category | str lowercase) in ($i.vault.name)($extra)" }
  })
  let ids = ($items | each { |i|
    { value: $i.id, description: $"($i.title) • ($i.category | str lowercase) in ($i.vault.name)" }
  })
  $titles | append $ids
}

# Complete 1Password document names and IDs
def "nu-complete op documents" [] {
  let data = (nu-complete op cached-json "documents" [document list --format json] 30min)
  $data | each { |d|
    let title = ($d.title? | default ($d.id? | default ""))
    [
      { value: $title, description: "document" }
      { value: ($d.id? | default $title), description: $title }
    ]
  } | flatten
}

# Complete 1Password vault names
def "nu-complete op vaults" [] {
  nu-complete op cached-json "vaults" [vault list --format json] 30min
  | each { |v| { value: $v.name, description: $"($v.items?) items" } }
}

# Complete 1Password users by name and email
def "nu-complete op users" [] {
  nu-complete op cached-json "users" [user list --format json] 30min
  | each { |u|
    let kind = ($u.type? | default "member" | str lowercase)
    [
      { value: $u.name, description: $"($u.email) • ($kind)" }
      { value: $u.email, description: $"($u.name) • ($kind)" }
    ]
  } | flatten
}

# Complete 1Password groups
def "nu-complete op groups" [] {
  nu-complete op cached-json "groups" [group list --format json] 30min
  | each { |g| { value: $g.name, description: ($g.description? | default "") } }
}

# Complete 1Password item categories
def "nu-complete op item categories" [] {
  [
    { value: "API Credential",          description: "API credentials and tokens" }
    { value: "api-credential",          description: "API credentials and tokens" }
    { value: "Bank Account",            description: "Bank account details" }
    { value: "bank-account",            description: "Bank account details" }
    { value: "Credit Card",             description: "Credit and debit cards" }
    { value: "credit-card",             description: "Credit and debit cards" }
    { value: "Crypto Wallet",           description: "Cryptocurrency wallets and seed phrases" }
    { value: "crypto-wallet",           description: "Cryptocurrency wallets and seed phrases" }
    { value: "Database",                description: "Database connection credentials" }
    { value: "database",                description: "Database connection credentials" }
    { value: "Document",                description: "Stored document files" }
    { value: "document",                description: "Stored document files" }
    { value: "Driver License",          description: "Driver licenses" }
    { value: "driver-license",          description: "Driver licenses" }
    { value: "Email Account",           description: "Email service credentials" }
    { value: "email-account",           description: "Email service credentials" }
    { value: "Identity",                description: "Personal identity details" }
    { value: "identity",                description: "Personal identity details" }
    { value: "Login",                   description: "Website and application logins" }
    { value: "login",                   description: "Website and application logins" }
    { value: "Medical Record",          description: "Medical records and notes" }
    { value: "medical-record",          description: "Medical records and notes" }
    { value: "Membership",              description: "Membership cards and numbers" }
    { value: "membership",              description: "Membership cards and numbers" }
    { value: "Outdoor License",         description: "Hunting, fishing, and recreation licenses" }
    { value: "outdoor-license",         description: "Hunting, fishing, and recreation licenses" }
    { value: "Passport",                description: "Passports and travel documents" }
    { value: "passport",                description: "Passports and travel documents" }
    { value: "Password",                description: "Simple passwords without login metadata" }
    { value: "password",                description: "Simple passwords without login metadata" }
    { value: "Reward Program",          description: "Loyalty and reward programs" }
    { value: "reward-program",          description: "Loyalty and reward programs" }
    { value: "SSH Key",                 description: "SSH keys and key pairs" }
    { value: "ssh-key",                 description: "SSH keys and key pairs" }
    { value: "Secure Note",             description: "Encrypted text notes" }
    { value: "secure-note",             description: "Encrypted text notes" }
    { value: "Server",                  description: "Server hardware and login info" }
    { value: "server",                  description: "Server hardware and login info" }
    { value: "Social Security Number",  description: "SSN / government national IDs" }
    { value: "social-security-number",  description: "SSN / government national IDs" }
    { value: "Software License",        description: "Software licenses and product keys" }
    { value: "software-license",        description: "Software licenses and product keys" }
    { value: "Wireless Router",         description: "Wi-Fi network and router credentials" }
    { value: "wireless-router",         description: "Wi-Fi network and router credentials" }
  ]
}

# Complete output formats
def "nu-complete op formats" [] {
  [
    { value: "human-readable", description: "Human-readable format (default)" }
    { value: "json",           description: "Machine-readable JSON output" }
  ]
}

# Complete character encodings
def "nu-complete op encodings" [] {
  [
    { value: "UTF-8",     description: "UTF-8 character encoding (default)" }
    { value: "SHIFT_JIS", description: "Shift JIS Japanese encoding" }
    { value: "gbk",       description: "GBK Chinese encoding" }
  ]
}

# Complete boolean values
def "nu-complete op boolean" [] {
  [
    { value: "true",  description: "Enable option" }
    { value: "false", description: "Disable option" }
  ]
}

# Complete Travel Mode status
def "nu-complete op travel-mode" [] {
  [
    { value: "on",  description: "Enable Travel Mode" }
    { value: "off", description: "Disable Travel Mode" }
  ]
}

# Complete group roles
def "nu-complete op group-roles" [] {
  [
    { value: "member",  description: "Standard group member" }
    { value: "manager", description: "Group manager with administrative rights" }
  ]
}

# Complete SSH key generation types
def "nu-complete op ssh-key-types" [] {
  [
    { value: "ed25519", description: "Ed25519 elliptic curve key (recommended)" }
    { value: "rsa",     description: "RSA key (4096-bit default)" }
    { value: "rsa2048", description: "RSA key (2048-bit)" }
    { value: "rsa3072", description: "RSA key (3072-bit)" }
    { value: "rsa4096", description: "RSA key (4096-bit)" }
  ]
}

# Complete update channels
def "nu-complete op channels" [] {
  [
    { value: "stable", description: "Stable release channel" }
    { value: "beta",   description: "Beta release channel" }
  ]
}

# Complete completion target shells
def "nu-complete op shells" [] {
  [
    { value: "bash",       description: "Bourne Again SHell (Bash)" }
    { value: "zsh",        description: "Z Shell (Zsh)" }
    { value: "fish",       description: "Friendly Interactive Shell (Fish)" }
    { value: "powershell", description: "PowerShell" }
  ]
}

# Complete vault icon names
def "nu-complete op vault icons" [] {
  [
    "airplane", "application", "art-supplies", "bankers-box", "brown-briefcase",
    "brown-gate", "buildings", "cabin", "castle", "circle-of-dots", "coffee",
    "color-wheel", "curtained-window", "document", "doughnut", "fence",
    "galaxy", "gears", "globe", "green-backpack", "green-gem", "handshake",
    "heart-with-monitor", "house", "id-card", "jet", "large-ship", "luggage",
    "plant", "porthole", "puzzle", "rainbow", "record", "round-door",
    "sandals", "scales", "screwdriver", "shop", "tall-window", "treasure-chest",
    "vault-door", "vehicle", "wallet", "wrench"
  ]
}

# Complete vault permissions
def "nu-complete op vault permissions" [] {
  [
    { value: "allow_viewing",            description: "Grant viewing permissions" }
    { value: "view_items",               description: "View item details" }
    { value: "view_and_copy_passwords",  description: "View and copy passwords" }
    { value: "view_item_history",        description: "View item revision history" }
    { value: "allow_editing",            description: "Grant editing permissions" }
    { value: "create_items",             description: "Create new items in vault" }
    { value: "edit_items",               description: "Modify existing items in vault" }
    { value: "archive_items",            description: "Archive items in vault" }
    { value: "delete_items",             description: "Delete items from vault" }
    { value: "import_items",             description: "Import items into vault" }
    { value: "export_items",             description: "Export items from vault" }
    { value: "copy_and_share_items",     description: "Copy and share items from vault" }
    { value: "print_items",              description: "Print items from vault" }
    { value: "allow_managing",           description: "Grant vault management permissions" }
    { value: "manage_vault",             description: "Manage vault settings and permissions" }
  ]
}

# Complete Events API features
def "nu-complete op events-api features" [] {
  [
    { value: "signinattempts", description: "Report sign-in attempts" }
    { value: "itemusages",     description: "Report item usage events" }
    { value: "auditevents",    description: "Report audit events" }
  ]
}

# Complete available shell plugins
def "nu-complete op plugins" [] {
  try {
    let res = (do { ^op plugin list } | complete)
    if $res.exit_code != 0 or ($res.stdout | is-empty) { return [] }
    $res.stdout
    | lines
    | skip 1
    | parse -r '^(?P<exec>\S+)\s+(?P<name>.+?)\s{2,}(?P<fields>.*)$'
    | where exec != "-"
    | each { |p| { value: $p.exec, description: $"($p.name) plugin" } }
    | sort-by value
  } catch {
    []
  }
}

# Complete secret reference prefix syntax
def "nu-complete op secret-reference" [] {
  [
    { value: "op://", description: "Secret reference format: op://<vault>/<item>/<field>" }
  ]
}

# Known extern subcommands for deduplication
def "nu-complete op extern-subcommands" [] {
  [
    "account", "connect", "document", "events-api", "group", "item", "plugin",
    "service-account", "user", "vault", "completion", "inject", "read", "run",
    "signin", "signout", "update", "whoami"
  ]
}

# Fallback completer for op subcommands
def "nu-complete op subcommands-fallback" [] {
  let known = (nu-complete op extern-subcommands)
  [
    { value: "account",         description: "Manage your locally configured 1Password accounts" }
    { value: "connect",         description: "Manage Connect server instances and tokens" }
    { value: "document",        description: "Perform CRUD operations on Document items in your vaults" }
    { value: "events-api",      description: "Manage Events API integrations in your 1Password account" }
    { value: "group",           description: "Manage the groups in your 1Password account" }
    { value: "item",            description: "Perform CRUD operations on the 1Password items in your vaults" }
    { value: "plugin",          description: "Manage the shell plugins you use to authenticate third-party CLIs" }
    { value: "service-account", description: "Manage service accounts" }
    { value: "user",            description: "Manage users within this 1Password account" }
    { value: "vault",           description: "Manage permissions and perform CRUD operations on your 1Password vaults" }
    { value: "completion",      description: "Generate shell completion information" }
    { value: "inject",          description: "Inject secrets into a config file" }
    { value: "read",            description: "Read a secret reference" }
    { value: "run",             description: "Pass secrets as environment variables to a process" }
    { value: "signin",          description: "Sign in to a 1Password account" }
    { value: "signout",         description: "Sign out of a 1Password account" }
    { value: "update",          description: "Check for and download updates" }
    { value: "whoami",          description: "Get information about a signed-in account" }
  ] | where { |it| $it.value not-in $known }
}

# ==============================================================================
# Main Command & Subcommands
# ==============================================================================

# 1Password CLI brings 1Password to your terminal
export extern "op" [
  command?: string@"nu-complete op subcommands-fallback" # Subcommand to run
  --version(-v)                                        # Print version for op
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]


# Manage your locally configured 1Password accounts
export extern "op account" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Add an account to sign in to for the first time
export extern "op account add" [
  --address: string # The sign-in address for your account.
  --email: string # The email address associated with your account.
  --raw # Only return the session token.
  --shorthand: string # Set a custom account shorthand for your account.
  --signin # Immediately sign in to the added account.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get details about your account
export extern "op account get" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List users and accounts set up on this device
export extern "op account list" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Remove a 1Password account from this device
export extern "op account forget" [
  account?: string@"nu-complete op accounts" # Account to forget
  --all # Forget all authenticated accounts.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Manage Connect server instances and tokens
export extern "op connect" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Grant a group access to manage Secrets Automation
export extern "op connect group grant" [
  --all-servers # Grant access to all current and future servers in the authenticated account.
  --group: string@"nu-complete op groups"              # The group to receive access.
  --server: string # The server to grant access to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Revoke a group's access to manage Secrets Automation
export extern "op connect group revoke" [
  --all-servers # Revoke access to all current and future servers in the authenticated account.
  --group: string@"nu-complete op groups"              # The group to revoke access from.
  --server: string # The server to revoke access to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Set up a Connect server
export extern "op connect server create" [
  name: string # Name of Connect server
  --force(-f) # Do not prompt for confirmation when overwriting credential files.
  --vaults: string # Grant the Connect server access to these vaults.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get a Connect server
export extern "op connect server get" [
  server?: string # Server name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Rename a Connect server
export extern "op connect server edit" [
  server: string # Server name or ID
  --name: string # Change the server's name.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Remove a Connect server
export extern "op connect server delete" [
  server?: string # Server name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List Connect servers
export extern "op connect server list" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Issue a token for a 1Password Connect server
export extern "op connect token create" [
  token_name: string # Name of token
  --expires-in: string # Set how long the Connect token is valid for in (s)econds, (m)inutes, (h)ours, (d)ays, and/or (w)eeks.
  --server: string # Issue a token for this server.
  --vault: string@"nu-complete op vaults"              # Issue a token on these vaults.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Rename a Connect server token
export extern "op connect token edit" [
  token: string # Token to edit
  --name: string # Change the token's name.
  --server: string # Only look for tokens for this 1Password Connect server.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Revoke a token for a Connect server
export extern "op connect token delete" [
  token?: string # Token to delete
  --server: string # Only look for tokens for this 1Password Connect server.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get a list of tokens
export extern "op connect token list" [
  --server: string # Only list tokens for this Connect server.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Grant a Connect server access to a vault
export extern "op connect vault grant" [
  --server: string # The server to be granted access.
  --vault: string@"nu-complete op vaults"              # The vault to grant access to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Revoke a Connect server's access to a vault
export extern "op connect vault revoke" [
  --server: string # The server to revoke access from.
  --vault: string@"nu-complete op vaults"              # The vault to revoke a server's access to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Perform CRUD operations on Document items in your vaults
export extern "op document" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Create a document item
export extern "op document create" [
  file?: path # Path to file, or - for stdin
  --file-name: string # Set the file's name.
  --tags: string # Set the tags to the specified (comma-separated) values.
  --title: string # Set the document item's title.
  --vault: string@"nu-complete op vaults"              # Save the document in this vault. Default: Private, Personal, or Employee, depending on your account type.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Download a document
export extern "op document get" [
  item: string@"nu-complete op documents"              # Document item name or ID
  --file-mode: string # Set filemode for the output file. It is ignored without the --out-file flag. (default 0600)
  --force # Forcibly print an unintelligible document to an interactive terminal. If --out-file is specified, save the document to a file without prompting for confirmation.
  --include-archive # Include document items in the Archive. Can also be set using OP_INCLUDE_ARCHIVE environment variable.
  --out-file(-o): path # Save the document to the file path instead of stdout.
  --vault: string@"nu-complete op vaults"              # Look for the document in this vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Edit a document item
export extern "op document edit" [
  item: string@"nu-complete op documents"              # Document item name or ID
  file?: path # Path to new file, or - for stdin
  --file-name: string # Set the file's name.
  --tags: string # Set the tags to the specified (comma-separated) values. An empty value removes all tags.
  --title: string # Set the document item's title.
  --vault: string@"nu-complete op vaults"              # Look up document in this vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Delete or archive a document item
export extern "op document delete" [
  item?: string@"nu-complete op documents"             # Document item name or ID
  --archive # Move the document to the Archive.
  --vault: string@"nu-complete op vaults"              # Delete the document in this vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get a list of documents
export extern "op document list" [
  --include-archive # Include document items in the Archive. Can also be set using OP_INCLUDE_ARCHIVE environment variable.
  --vault: string@"nu-complete op vaults"              # Only list documents in this vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Manage Events API integrations in your 1Password account
export extern "op events-api" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Set up an integration with the Events API
export extern "op events-api create" [
  name: string # Integration name
  --expires-in: string # Set how the long the events-api token is valid for in (s)econds, (m)inutes, (h)ours, (d)ays, and/or (w)eeks.
  --features: string@"nu-complete op events-api features" # Set the comma-separated list of features the integration token can be used for. Options: 'signinattempts', 'itemusages', 'auditevents'.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Manage the groups in your 1Password account
export extern "op group" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Create a group
export extern "op group create" [
  name: string # Group name
  --description: string # Set the group's description.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get details about a group
export extern "op group get" [
  group?: string@"nu-complete op groups"               # Group name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Edit a group's name or description
export extern "op group edit" [
  group?: string@"nu-complete op groups"               # Group name or ID
  --description: string # Change the group's description.
  --name: string # Change the group's name.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Remove a group
export extern "op group delete" [
  group?: string@"nu-complete op groups"               # Group name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List groups
export extern "op group list" [
  --user: string@"nu-complete op users"                # List groups that a user belongs to.
  --vault: string@"nu-complete op vaults"              # List groups that have direct access to a vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Add a user to a group
export extern "op group user grant" [
  --group: string@"nu-complete op groups"              # Specify the group to add the user to.
  --role: string@"nu-complete op group-roles" # Specify the user's role as a member or manager. Default: member.
  --user: string@"nu-complete op users"                # Specify the user to add to the group.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Remove a user from a group
export extern "op group user revoke" [
  --group: string@"nu-complete op groups"              # Specify the group to remove the user from.
  --user: string@"nu-complete op users"                # Specify the user to remove from the group.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Retrieve users that belong to a group
export extern "op group user list" [
  group: string@"nu-complete op groups"                # Group name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Perform CRUD operations on the 1Password items in your vaults
export extern "op item" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Create an item
export extern "op item create" [
  ...assignment: string # Field assignments [section.]field[type]=val or -
  --category: string@"nu-complete op item categories" # Set the item's category.
  --dry-run # Test the command and output a preview of the resulting item.
  --favorite # Add item to favorites.
  --reveal # Don't conceal sensitive fields.
  --ssh-generate-key: string@"nu-complete op ssh-key-types" # The type of SSH key to create: Ed25519 or RSA. For RSA, specify 2048, 3072, or 4096 (default) bits.
  --tags: string # Set the tags to the specified (comma-separated) values.
  --template: path # Specify the file path to read an item template from.
  --title: string # Set the item's title.
  --url: string # Set the URL associated with the item
  --vault: string@"nu-complete op vaults"              # Save the item in this vault. Default: Private, Personal, or Employee, depending on your account type.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get an item's details
export extern "op item get" [
  item?: string@"nu-complete op items"                 # Item name, ID, or share link
  --fields: string # Return data from specific fields. Use 'label=' to get the field by name or 'type=' to filter fields by type. Specify multiple in a comma-separated list.
  --include-archive # Include items in the Archive. Can also be set using OP_INCLUDE_ARCHIVE environment variable.
  --otp # Output the primary one-time password for this item.
  --reveal # Don't conceal sensitive fields.
  --share-link # Get a shareable link for the item.
  --vault: string@"nu-complete op vaults"              # Look for the item in this vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Edit an item's details
export extern "op item edit" [
  item?: string@"nu-complete op items"                 # Item name, ID, or share link
  ...assignment: string # Field assignments
  --dry-run # Perform a dry run of the command and output a preview of the resulting item.
  --favorite # Whether this item is a favorite item. Options: true, false --generate-password[=recipe]   Give the item a randomly generated password.
  --reveal # Don't conceal sensitive fields.
  --tags: string # Set the tags to the specified (comma-separated) values. An empty value will remove all tags.
  --template: path # Specify the filepath to read an item template from.
  --title: string # Set the item's title.
  --url: string # Set the URL associated with the item
  --vault: string@"nu-complete op vaults"              # Edit the item in this vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Delete or archive an item
export extern "op item delete" [
  item?: string@"nu-complete op items"                 # Item name, ID, or share link
  --archive # Move the item to the Archive.
  --vault: string@"nu-complete op vaults"              # Look for the item in this vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List items
export extern "op item list" [
  --categories: string@"nu-complete op item categories" # Only list items in these categories (comma-separated).
  --favorite # Only list favorite items
  --include-archive # Include items in the Archive. Can also be set using OP_INCLUDE_ARCHIVE environment variable.
  --long # Output a more detailed item list.
  --tags: string # Only list items with these tags (comma-separated).
  --vault: string@"nu-complete op vaults"              # Only list items in this vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Move an item between vaults
export extern "op item move" [
  item?: string@"nu-complete op items"                 # Item name, ID, or share link
  --current-vault: string@"nu-complete op vaults"      # Vault where the item is currently saved.
  --destination-vault: string@"nu-complete op vaults"  # The vault you want to move the item to.
  --reveal # Don't conceal sensitive fields.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Share an item
export extern "op item share" [
  item: string@"nu-complete op items"                  # Item name or ID to share
  --emails: string # Email addresses to share with.
  --expires-in: string # Expire link after the duration specified in (s)econds, (m)inutes, (h)ours, (d)ays, and/or (w)eeks. (default 7d)
  --vault: string@"nu-complete op vaults"              # Look for the item in this vault.
  --view-once # Expire link after a single view.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get an item template
export extern "op item template get" [
  category?: string@"nu-complete op item categories" # Template category
  --file-mode: string # Set filemode for the output file. It is ignored without the --out-file flag. (default 0600)
  --force(-f) # Do not prompt for confirmation.
  --out-file(-o): path # Write the template to a file instead of stdout.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get a list of templates
export extern "op item template list" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Manage the shell plugins you use to authenticate third-party CLIs
export extern "op plugin" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Import credentials for a shell plugin
export extern "op plugin credential import" [
  plugin: string@"nu-complete op plugins" # Plugin executable name
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List all available shell plugins
export extern "op plugin list" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Clear shell plugin configuration
export extern "op plugin clear" [
  plugin: string@"nu-complete op plugins" # Plugin executable name
  --all # Clear all configurations for this plugin that apply to this directory and/or terminal session, including the global default.
  --force(-f) # Apply immediately without asking for confirmation.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Configure a shell plugin
export extern "op plugin init" [
  plugin?: string@"nu-complete op plugins" # Plugin executable name
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Inspect your existing shell plugin configurations
export extern "op plugin inspect" [
  plugin?: string@"nu-complete op plugins" # Plugin executable name
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Provision credentials from 1Password and run command
export extern "op plugin run" [
  ...command: string # Command and arguments to run
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Manage service accounts
export extern "op service-account" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Create a service account
export extern "op service-account create" [
  name: string # Service account name
  --can-create-vaults # Allow the service account to create new vaults.
  --expires-in: string # Set how long the service account is valid for in (s)econds, (m)inutes, (h)ours, (d)ays, or (w)eeks.
  --raw # Only return the service account token.
  --vault: string # Give access to this vault with a set of permissions. Has syntax <vault-name>:<permission>[,<permission>]
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Retrieve rate limit usage for a service account
export extern "op service-account ratelimit" [
  account?: string # Service account name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Manage users within this 1Password account
export extern "op user" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Provision a user in the authenticated account
export extern "op user provision" [
  --email: string # Provide the user's email address.
  --language: string # Provide the user's account language. (default \"en\")
  --name: string # Provide the user's name.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Confirm a user
export extern "op user confirm" [
  user?: string@"nu-complete op users"                 # User email, name, or ID
  --all # Confirm all unconfirmed users.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get details about a user
export extern "op user get" [
  user?: string@"nu-complete op users"                 # User email, name, or ID
  --fingerprint # Get the user's public key fingerprint.
  --me # Get the authenticated user's details.
  --public-key # Get the user's public key.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Edit a user's name or Travel Mode status
export extern "op user edit" [
  user?: string@"nu-complete op users"                 # User email, name, or ID
  --name: string # Set the user's name.
  --travel-mode: string@"nu-complete op travel-mode" # Turn Travel Mode on or off for the user. (default off)
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Suspend a user
export extern "op user suspend" [
  user?: string@"nu-complete op users"                 # User email, name, or ID
  --deauthorize-devices-after: string # Deauthorize the user's devices after a time (rounded down to seconds).
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Reactivate a suspended user
export extern "op user reactivate" [
  user?: string@"nu-complete op users"                 # User email, name, or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Remove a user and all their data from the account
export extern "op user delete" [
  user?: string@"nu-complete op users"                 # User email, name, or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List users
export extern "op user list" [
  --group: string@"nu-complete op groups"              # List users who belong to a group.
  --vault: string@"nu-complete op vaults"              # List users who have direct access to vault.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Begin recovery for users in your 1Password account
export extern "op user recovery begin" [
  user?: string@"nu-complete op users"                 # User email, name, or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Manage permissions and perform CRUD operations on your 1Password vaults
export extern "op vault" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Create a new vault
export extern "op vault create" [
  name: string # Name of the vault
  --allow-admins-to-manage: string@"nu-complete op boolean" # Set whether administrators can manage the vault. If not provided, the default policy for the account applies.
  --description: string # Set the group's description.
  --icon: string@"nu-complete op vault icons" # Set the vault icon.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get details about a vault
export extern "op vault get" [
  vault?: string@"nu-complete op vaults"               # Vault name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Edit a vault's name, description, icon, or Travel Mode status
export extern "op vault edit" [
  vault?: string@"nu-complete op vaults"               # Vault name or ID
  --description: string # Change the vault's description.
  --icon: string@"nu-complete op vault icons" # Change the vault's icon.
  --name: string # Change the vault's name.
  --travel-mode: string@"nu-complete op travel-mode" # Turn Travel Mode on or off for the vault. (default off)
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Remove a vault
export extern "op vault delete" [
  vault?: string@"nu-complete op vaults"               # Vault name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List all vaults in the account
export extern "op vault list" [
  --group: string@"nu-complete op groups"              # List vaults a group has access to.
  --permission: string@"nu-complete op vault permissions" # List only vaults that the specified user/group has this permission for.
  --user: string@"nu-complete op users"                # List vaults that a given user has access to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Grant a group permissions to a vault
export extern "op vault group grant" [
  --group: string@"nu-complete op groups"              # The group to receive access.
  --no-input: string # Do not prompt for input on interactive terminal.
  --permissions: string@"nu-complete op vault permissions" # The permissions to grant to the group.
  --vault: string@"nu-complete op vaults"              # The vault to grant group permissions to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Revoke a group's permissions to a vault
export extern "op vault group revoke" [
  --group: string@"nu-complete op groups"              # The group to revoke access from.
  --no-input: string # Do not prompt for input on interactive terminal.
  --permissions: string@"nu-complete op vault permissions" # The permissions to revoke from the group.
  --vault: string@"nu-complete op vaults"              # The vault to revoke access to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List all the groups that have access to the given vault
export extern "op vault group list" [
  vault?: string@"nu-complete op vaults"               # Vault name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Grant a user access to a vault
export extern "op vault user grant" [
  --no-input: string # Do not prompt for input on interactive terminal.
  --permissions: string@"nu-complete op vault permissions" # The permissions to grant to the user.
  --user: string@"nu-complete op users"                # The user to receive access.
  --vault: string@"nu-complete op vaults"              # The vault to grant access to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Revoke a portion or the entire access of a user to a vault
export extern "op vault user revoke" [
  --no-input: string # Do not prompt for input on interactive terminal.
  --permissions: string@"nu-complete op vault permissions" # The permissions to revoke from the user.
  --user: string@"nu-complete op users"                # The user to revoke access from.
  --vault: string@"nu-complete op vaults"              # The vault to revoke access to.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# List all users with access to the vault and their permissions
export extern "op vault user list" [
  vault: string@"nu-complete op vaults"                # Vault name or ID
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Generate shell completion information
export extern "op completion" [
  shell: string@"nu-complete op shells" # Shell (bash, zsh, fish, powershell)
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Inject secrets into a config file
export extern "op inject" [
  --file-mode: string # Set filemode for the output file. It is ignored without the --out-file flag. (default 0600)
  --force(-f) # Do not prompt for confirmation.
  --in-file(-i): path # The filename of a template file to inject.
  --out-file(-o): path # Write the injected template to a file instead of stdout.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Read a secret reference
export extern "op read" [
  reference: string@"nu-complete op secret-reference" # Secret reference (op://vault/item/field)
  --file-mode: string # Set filemode for the output file. It is ignored without the --out-file flag. (default 0600)
  --force(-f) # Do not prompt for confirmation.
  --no-newline(-n) # Do not print a new line after the secret.
  --out-file(-o): path # Write the secret to a file instead of stdout.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Pass secrets as environment variables to a process
export extern "op run" [
  ...command: string # Command to run with secrets injected
  --env-file: path # Enable Dotenv integration with specific Dotenv files to parse. For example: --env-file=.env.
  --no-masking # Disable masking of secrets on stdout and stderr.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Sign in to a 1Password account
export extern "op signin" [
  --force(-f) # Ignore warnings and print raw output from this command.
  --raw # Only return the session token.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Sign out of a 1Password account
export extern "op signout" [
  --all # Sign out of all signed-in accounts.
  --forget # Remove the details for a 1Password account from this device.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Check for and download updates
export extern "op update" [
  --channel: string@"nu-complete op channels" # Look for updates from a specific channel. allowed: stable, beta
  --directory: path # Download the update to this ''path''.
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]

# Get information about a signed-in account
export extern "op whoami" [
  --account: string@"nu-complete op accounts"          # Select the account to execute the command by account shorthand, sign-in address, account ID, or user ID
  --cache: string@"nu-complete op boolean"             # Store and use cached information (true, false)
  --config: path                                       # Use this configuration directory
  --debug                                              # Enable debug mode
  --encoding: string@"nu-complete op encodings"        # Character encoding type (UTF-8, SHIFT_JIS, gbk)
  --format: string@"nu-complete op formats"            # Output format (human-readable, json)
  --iso-timestamps                                     # Format timestamps according to ISO 8601 / RFC 3339
  --no-color                                           # Print output without color
  --session: string                                    # Authenticate with this session token
  --help(-h)                                           # Get help for command
]
