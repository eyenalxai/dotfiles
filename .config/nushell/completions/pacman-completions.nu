# pacman.nu - Comprehensive autocompletion for Arch Linux pacman
# Supports operations, flags, bundling, and context-aware target completion

# Complete installed packages with version description
def installed-pkgs [] {
    ^pacman -Q
    | lines
    | parse "{value} {description}"
}

# Complete sync (repository) packages
def sync-pkgs [] {
    let yay_cache = ("~/.cache/yay/completion.cache" | path expand)
    if ($yay_cache | path exists) {
        open --raw $yay_cache
        | lines
        | parse "{value}\t{description}"
        | where description != "AUR"
    } else {
        ^pacman -Slq | lines
    }
}

# Complete package groups
def pkg-groups [] {
    ^pacman -Sgq | lines | uniq
}

# Complete repositories
def repo-list [] {
    ^pacman-conf --repo-list | lines
}

# Complete color options
def color-choices [] {
    ["auto", "always", "never"]
}

# Positional targets completer for pacman
def pacman-operations [] {
    [
        { value: "-S", description: "Synchronize packages" }
        { value: "-Syu", description: "Synchronize databases and upgrade system" }
        { value: "-Ss", description: "Search remote repositories for matching strings" }
        { value: "-Si", description: "View remote package information" }
        { value: "-Sy", description: "Download fresh package databases from server" }
        { value: "-Su", description: "Upgrade installed packages" }
        { value: "-R", description: "Remove packages from the system" }
        { value: "-Rns", description: "Remove package, dependencies, and configuration files" }
        { value: "-Q", description: "Query the package database" }
        { value: "-Qe", description: "List explicitly installed packages" }
        { value: "-Qm", description: "List foreign (AUR / manually installed) packages" }
        { value: "-Qs", description: "Search installed packages for matching strings" }
        { value: "-Qi", description: "View installed package information" }
        { value: "-Ql", description: "List files owned by installed package" }
        { value: "-Qo", description: "Search for package that owns specified file" }
        { value: "-F", description: "Query the files database" }
        { value: "-Fs", description: "Search for packages containing specified file" }
        { value: "-Fl", description: "List files owned by given package from files db" }
        { value: "-Fy", description: "Download fresh files databases from server" }
        { value: "-U", description: "Upgrade or add a local package (.pkg.tar.zst)" }
        { value: "-D", description: "Modify the package database (--asdeps, --asexplicit)" }
        { value: "-T", description: "Check dependencies" }
        { value: "-h", description: "Display help and syntax" }
        { value: "-V", description: "Display version and exit" }
        { value: "--sync", description: "Synchronize packages" }
        { value: "--remove", description: "Remove packages from the system" }
        { value: "--query", description: "Query the package database" }
        { value: "--files", description: "Query the files database" }
        { value: "--upgrade", description: "Upgrade or add a local package" }
        { value: "--database", description: "Modify the package database" }
        { value: "--deptest", description: "Check dependencies" }
        { value: "--help", description: "Display help and syntax" }
        { value: "--version", description: "Display version and exit" }
    ]
}

# Positional targets completer for pacman
def complete-pacman-targets [context: string] {
    let words = ($context | split row -r '\s+' | drop 1)
    let current = ($context | split row -r '\s+' | last)
    let prev_pkgs = ($words | where { |it| not ($it starts-with "-") and ($it != "pacman") and ($it != "sudo") })

    # Check operations
    let is_sync = ($words | any { |w| ($w =~ '^-[a-z]*S[a-zA-Z]*$') or ($w == '--sync') })
    let is_remove = ($words | any { |w| ($w =~ '^-[a-z]*R[a-zA-Z]*$') or ($w == '--remove') })
    let is_query = ($words | any { |w| ($w =~ '^-[a-z]*Q[a-zA-Z]*$') or ($w == '--query') })
    let is_database = ($words | any { |w| ($w =~ '^-[a-z]*D[a-zA-Z]*$') or ($w == '--database') })
    let is_upgrade = ($words | any { |w| ($w =~ '^-[a-z]*U[a-zA-Z]*$') or ($w == '--upgrade') })
    let is_files = ($words | any { |w| ($w =~ '^-[a-z]*F[a-zA-Z]*$') or ($w == '--files') })
    let is_deptest = ($words | any { |w| ($w =~ '^-[a-z]*T[a-zA-Z]*$') or ($w == '--deptest') })
    let is_help = ($words | any { |w| ($w =~ '^-[a-z]*h[a-zA-Z]*$') or ($w == '--help') })
    let is_version = ($words | any { |w| ($w =~ '^-[a-z]*V[a-zA-Z]*$') or ($w == '--version') })

    let is_owns = ($words | any { |w| ($w =~ '^-[a-zA-Z]*o[a-zA-Z]*$') or ($w == '--owns') })
    let is_file_arg = ($words | any { |w| ($w =~ '^-[a-zA-Z]*p[a-zA-Z]*$') or ($w == '--file') })
    let is_group = ($words | any { |w| ($w =~ '^-[a-zA-Z]*g[a-zA-Z]*$') or ($w == '--groups') or ($w == '--ignoregroup') })
    let is_repo_list = ($words | any { |w| ($w =~ '^-[a-zA-Z]*l[a-zA-Z]*$') or ($w == '--list') })
    let is_clean = ($words | any { |w| ($w =~ '^-[a-zA-Z]*c[a-zA-Z]*$') or ($w == '--clean') })

    let has_operation = ($is_sync or $is_remove or $is_query or $is_database or $is_upgrade or $is_files or $is_deptest or $is_help or $is_version)

    # Suggest operations when no operation is specified
    if not $has_operation {
        return (pacman-operations)
    }

    if $is_help or $is_version {
        return []
    }

    if $is_sync and $is_clean {
        return []
    }

    # File completions fallback (return null so Nushell handles files)
    if $is_upgrade or $is_owns or $is_file_arg {
        return null
    }

    # Files database operation
    if $is_files {
        if $is_repo_list {
            let pkgs = (sync-pkgs)
            return (if ($prev_pkgs | is-empty) { $pkgs } else { $pkgs | where { |p| $p.value not-in $prev_pkgs } })
        }
        return null
    }

    # Group completion
    if $is_group {
        let groups = (pkg-groups)
        return (if ($prev_pkgs | is-empty) { $groups } else { $groups | where { |g| $g not-in $prev_pkgs } })
    }

    # Repo list completion for -Sl
    if $is_repo_list and not $is_query {
        let repos = (repo-list)
        return (if ($prev_pkgs | is-empty) { $repos } else { $repos | where { |r| $r not-in $prev_pkgs } })
    }

    # Installed packages for removal, query, or database operations
    if $is_remove or $is_query or $is_database {
        let pkgs = (installed-pkgs)
        return (if ($prev_pkgs | is-empty) { $pkgs } else { $pkgs | where { |p| $p.value not-in $prev_pkgs } })
    }

    # Default: sync packages from repositories
    let pkgs = (sync-pkgs)
    if ($prev_pkgs | is-empty) {
        $pkgs
    } else {
        if (($pkgs | first? | describe) =~ "record") {
            $pkgs | where { |p| $p.value not-in $prev_pkgs }
        } else {
            $pkgs | where { |p| $p not-in $prev_pkgs }
        }
    }
}

# Pacman package manager
export extern pacman [
    --help(-h)                                      # Display syntax for the given operation
    --version(-V)                                   # Display version and exit
    --database(-D)                                  # Modify the package database
    --files(-F)                                     # Query the files database
    --query(-Q)                                     # Query the package database
    --remove(-R)                                    # Remove packages from the system
    --sync(-S)                                      # Synchronize packages
    --deptest(-T)                                   # Check dependencies
    --upgrade(-U)                                   # Upgrade or add a local package (.pkg.tar.zst)

    # General / Sync options
    --sysupgrade(-u)                                # Upgrade installed packages (-uu enables downgrades)
    --refresh(-y)                                   # Download fresh package databases (-yy to force refresh)
    --search                                        # Search package databases for matching strings
    --info                                          # View package information (-ii for extended info)
    --list                                          # View list of packages in a repo or files in a package
    --clean                                         # Remove old packages from cache directory (-cc for all)
    --groups                                        # View all members of a package group (-gg for all)
    --downloadonly(-w)                              # Only download the target packages
    --nodeps                                        # Skip dependency version checks (-dd to skip all)
    --print                                         # Print the targets instead of performing operation
    --quiet(-q)                                     # Show less information for query and search
    --verbose(-v)                                   # Be verbose

    # Combined short flags with context-dependent meanings
    -c                                              # Clean cache (-S), cascade remove (-R), or changelog (-Q)
    -d                                              # Skip dependency checks (-S, -R, -U) or list dependencies (-Q)
    -s                                              # Search remote/local databases (-S, -Q) or recursive remove (-R)
    -p                                              # Print targets (-S, -R, -U) or query package file (-Q)
    -l                                              # List packages in repo (-S) or files owned by package (-Q, -F)
    -g                                              # View package groups (-S, -Q)
    -i                                              # View package information (-S, -Q)
    -k                                              # Check database validity (-D) or verify package files (-Q)
    -m                                              # List foreign packages (-Q) or machine-readable output (-F)
    -n                                              # Ignore backup files (-R) or list native packages (-Q)

    # Remove-specific options
    --cascade                                       # Remove target and all packages that depend on them
    --nosave                                        # Ignore backup (.pacsave) files
    --recursive                                     # Remove target and unused dependencies (-ss for all)
    --unneeded                                      # Remove unneeded packages
    --dbonly                                        # Only modify database entries, not package files

    # Query-specific options
    --changelog                                     # View the changelog of a package
    --deps                                          # List unrequired packages installed as dependencies
    --explicit(-e)                                  # List explicitly installed packages
    --check                                         # Check that package files exist (-kk for file properties)
    --foreign                                       # List installed packages not found in sync databases (AUR)
    --native                                        # List installed packages found in sync databases
    --owns(-o): path                                # Query the package that owns <file>
    --file: path                                    # Query package file (.pkg.tar.zst)
    --unrequired(-t)                                # List unrequired packages (-tt to include optional deps)
    --upgrades                                      # List out-of-date packages

    # Files-specific options
    --regex(-x)                                     # Enable regex for search in files database
    --machinereadable                               # Print in machine-readable format

    # Transaction options
    --needed                                        # Do not reinstall up to date packages
    --asdeps                                        # Install packages as non-explicitly installed
    --asexplicit                                    # Install packages as explicitly installed
    --noconfirm                                     # Do not ask for any confirmation
    --confirm                                       # Always ask for confirmation
    --overwrite: string                             # Overwrite conflicting files (can be used more than once)
    --assume-installed: string                      # Add a virtual package to satisfy dependencies
    --print-format: string                          # Specify how the targets should be printed
    --disable-download-timeout                      # Use relaxed timeouts for download
    --disable-sandbox                               # Disable downloader sandbox
    --disable-sandbox-filesystem                    # Disable filesystem sandbox
    --disable-sandbox-syscalls                      # Disable syscall sandbox
    --noprogressbar                                 # Do not show a progress bar when downloading
    --noscriptlet                                   # Do not execute the install scriptlet if one exists

    # Configuration and paths
    --cachedir: path                                # Alternate package cache location
    --color: string@color-choices                   # Colorize output (auto, always, never)
    --config: path                                  # Alternate configuration file
    --dbpath: path                                  # Alternate database location
    --root: path                                    # Alternate installation root
    --logfile: path                                 # Alternate log file
    --gpgdir: path                                  # Alternate home directory for GnuPG
    --hookdir: path                                 # Alternate hook location
    --sysroot: path                                 # Operate on a mounted guest system (root-only)
    --ignore: string@sync-pkgs                      # Ignore a package upgrade
    --ignoregroup: string@pkg-groups                # Ignore a group upgrade

    ...targets: string@complete-pacman-targets      # Packages, groups, or repositories to operate on
]

# Pacman with sudo
export extern "sudo pacman" [
    --help(-h)                                      # Display syntax for the given operation
    --version(-V)                                   # Display version and exit
    --database(-D)                                  # Modify the package database
    --files(-F)                                     # Query the files database
    --query(-Q)                                     # Query the package database
    --remove(-R)                                    # Remove packages from the system
    --sync(-S)                                      # Synchronize packages
    --deptest(-T)                                   # Check dependencies
    --upgrade(-U)                                   # Upgrade or add a local package (.pkg.tar.zst)

    # General / Sync options
    --sysupgrade(-u)                                # Upgrade installed packages (-uu enables downgrades)
    --refresh(-y)                                   # Download fresh package databases (-yy to force refresh)
    --search                                        # Search package databases for matching strings
    --info                                          # View package information (-ii for extended info)
    --list                                          # View list of packages in a repo or files in a package
    --clean                                         # Remove old packages from cache directory (-cc for all)
    --groups                                        # View all members of a package group (-gg for all)
    --downloadonly(-w)                              # Only download the target packages
    --nodeps                                        # Skip dependency version checks (-dd to skip all)
    --print                                         # Print the targets instead of performing operation
    --quiet(-q)                                     # Show less information for query and search
    --verbose(-v)                                   # Be verbose

    # Combined short flags with context-dependent meanings
    -c                                              # Clean cache (-S), cascade remove (-R), or changelog (-Q)
    -d                                              # Skip dependency checks (-S, -R, -U) or list dependencies (-Q)
    -s                                              # Search remote/local databases (-S, -Q) or recursive remove (-R)
    -p                                              # Print targets (-S, -R, -U) or query package file (-Q)
    -l                                              # List packages in repo (-S) or files owned by package (-Q, -F)
    -g                                              # View package groups (-S, -Q)
    -i                                              # View package information (-S, -Q)
    -k                                              # Check database validity (-D) or verify package files (-Q)
    -m                                              # List foreign packages (-Q) or machine-readable output (-F)
    -n                                              # Ignore backup files (-R) or list native packages (-Q)

    # Remove-specific options
    --cascade                                       # Remove target and all packages that depend on them
    --nosave                                        # Ignore backup (.pacsave) files
    --recursive                                     # Remove target and unused dependencies (-ss for all)
    --unneeded                                      # Remove unneeded packages
    --dbonly                                        # Only modify database entries, not package files

    # Query-specific options
    --changelog                                     # View the changelog of a package
    --deps                                          # List unrequired packages installed as dependencies
    --explicit(-e)                                  # List explicitly installed packages
    --check                                         # Check that package files exist (-kk for file properties)
    --foreign                                       # List installed packages not found in sync databases (AUR)
    --native                                        # List installed packages found in sync databases
    --owns(-o): path                                # Query the package that owns <file>
    --file: path                                    # Query package file (.pkg.tar.zst)
    --unrequired(-t)                                # List unrequired packages (-tt to include optional deps)
    --upgrades                                      # List out-of-date packages

    # Files-specific options
    --regex(-x)                                     # Enable regex for search in files database
    --machinereadable                               # Print in machine-readable format

    # Transaction options
    --needed                                        # Do not reinstall up to date packages
    --asdeps                                        # Install packages as non-explicitly installed
    --asexplicit                                    # Install packages as explicitly installed
    --noconfirm                                     # Do not ask for any confirmation
    --confirm                                       # Always ask for confirmation
    --overwrite: string                             # Overwrite conflicting files (can be used more than once)
    --assume-installed: string                      # Add a virtual package to satisfy dependencies
    --print-format: string                          # Specify how the targets should be printed
    --disable-download-timeout                      # Use relaxed timeouts for download
    --disable-sandbox                               # Disable downloader sandbox
    --disable-sandbox-filesystem                    # Disable filesystem sandbox
    --disable-sandbox-syscalls                      # Disable syscall sandbox
    --noprogressbar                                 # Do not show a progress bar when downloading
    --noscriptlet                                   # Do not execute the install scriptlet if one exists

    # Configuration and paths
    --cachedir: path                                # Alternate package cache location
    --color: string@color-choices                   # Colorize output (auto, always, never)
    --config: path                                  # Alternate configuration file
    --dbpath: path                                  # Alternate database location
    --root: path                                    # Alternate installation root
    --logfile: path                                 # Alternate log file
    --gpgdir: path                                  # Alternate home directory for GnuPG
    --hookdir: path                                 # Alternate hook location
    --sysroot: path                                 # Operate on a mounted guest system (root-only)
    --ignore: string@sync-pkgs                      # Ignore a package upgrade
    --ignoregroup: string@pkg-groups                # Ignore a group upgrade

    ...targets: string@complete-pacman-targets      # Packages, groups, or repositories to operate on
]
