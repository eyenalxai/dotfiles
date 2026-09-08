# yay.nu - Comprehensive autocompletion for yay (AUR helper & pacman wrapper)
# Supports official repositories and AUR packages, operations, flags, and options

# Complete installed packages with version description
def installed-pkgs [] {
    ^pacman -Q
    | lines
    | parse "{value} {description}"
}

# Complete all packages (official repos + AUR) from yay cache or yay -Pc
def all-pkgs [] {
    let cache = ("~/.cache/yay/completion.cache" | path expand)
    if ($cache | path exists) {
        open --raw $cache
    } else {
        ^yay -Pc
    }
    | lines
    | parse "{value}\t{description}"
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

# Complete yay answer menu options
def yay-answers [] {
    ["None", "All", "Installed", "NotInstalled"]
}

# Complete yay sortby fields
def yay-sortby [] {
    ["votes", "popularity", "id", "name", "base", "submitted", "modified"]
}

# Complete yay searchby fields
def yay-searchby [] {
    ["name", "name-desc", "maintainer", "depends", "makedepends", "optdepends", "checkdepends"]
}

# Yay operations and common action options suggested when no operation is specified
def yay-operations [] {
    [
        { value: "-S", description: "Synchronize packages (official repos + AUR)" }
        { value: "-Syu", description: "Update system and AUR packages" }
        { value: "-Ss", description: "Search remote repositories and AUR for matching strings" }
        { value: "-Si", description: "View remote / AUR package information" }
        { value: "-Sy", description: "Download fresh package databases from server" }
        { value: "-Su", description: "Upgrade installed packages" }
        { value: "-R", description: "Remove packages from the system" }
        { value: "-Rns", description: "Remove package, dependencies, and configuration files" }
        { value: "-Q", description: "Query the package database" }
        { value: "-Qe", description: "List explicitly installed packages" }
        { value: "-Qm", description: "List foreign / AUR packages" }
        { value: "-Qs", description: "Search installed packages for matching strings" }
        { value: "-Qi", description: "View installed package information" }
        { value: "-Ql", description: "List files owned by installed package" }
        { value: "-Qo", description: "Search for package that owns specified file" }
        { value: "-Y", description: "Perform yay specific operations" }
        { value: "-Yc", description: "Remove unneeded dependencies (clean orphans)" }
        { value: "-G", description: "Get PKGBUILD from ABS or AUR" }
        { value: "-P", description: "Print yay show information" }
        { value: "-Ps", description: "Display system package statistics" }
        { value: "-Pw", description: "Print Arch news" }
        { value: "-W", description: "Open webpage of target package" }
        { value: "-B", description: "Build PKGBUILD from directory" }
        { value: "-F", description: "Query the files database" }
        { value: "-U", description: "Upgrade or add a local package (.pkg.tar.zst)" }
        { value: "-D", description: "Modify the package database (--asdeps, --asexplicit)" }
        { value: "-T", description: "Check dependencies" }
        { value: "-a", description: "Assume targets are from the AUR" }
        { value: "-N", description: "Assume targets are from the repositories" }
        { value: "-h", description: "Display help and syntax" }
        { value: "-V", description: "Display version and exit" }
        { value: "--sync", description: "Synchronize packages" }
        { value: "--remove", description: "Remove packages from the system" }
        { value: "--query", description: "Query the package database" }
        { value: "--clean", description: "Remove unneeded dependencies (clean orphans)" }
        { value: "--getpkgbuild", description: "Get PKGBUILD from ABS or AUR" }
        { value: "--show", description: "Print yay show information" }
        { value: "--web", description: "Open webpage of target package" }
        { value: "--build", description: "Build PKGBUILD from directory" }
        { value: "--aur", description: "Assume targets are from the AUR" }
        { value: "--repo", description: "Assume targets are from the repositories" }
        { value: "--files", description: "Query the files database" }
        { value: "--upgrade", description: "Upgrade or add a local package" }
        { value: "--database", description: "Modify the package database" }
        { value: "--deptest", description: "Check dependencies" }
        { value: "--help", description: "Display help and syntax" }
        { value: "--version", description: "Display version and exit" }
    ]
}

# Positional targets completer for yay (exported for use in aliases like yaas)
export def complete-yay-targets [context: string] {
    let words = ($context | split row -r '\s+' | drop 1)
    let current = ($context | split row -r '\s+' | last)
    let prev_pkgs = ($words | where { |it| not ($it starts-with "-") and ($it != "yay") and ($it != "yaas") and ($it != "sudo") })

    # Check operations
    let is_yaas = ($words | any { |w| $w == 'yaas' })
    let is_sync = ($words | any { |w| ($w =~ '^-[a-z]*S[a-zA-Z]*$') or ($w == '--sync') })
    let is_remove = ($words | any { |w| ($w =~ '^-[a-z]*R[a-zA-Z]*$') or ($w == '--remove') })
    let is_query = ($words | any { |w| ($w =~ '^-[a-z]*Q[a-zA-Z]*$') or ($w == '--query') })
    let is_database = ($words | any { |w| ($w =~ '^-[a-z]*D[a-zA-Z]*$') or ($w == '--database') })
    let is_upgrade = ($words | any { |w| ($w =~ '^-[a-z]*U[a-zA-Z]*$') or ($w == '--upgrade') })
    let is_build = ($words | any { |w| ($w =~ '^-[a-z]*B[a-zA-Z]*$') or ($w == '--build') })
    let is_getpkgbuild = ($words | any { |w| ($w =~ '^-[a-z]*G[a-zA-Z]*$') or ($w == '--getpkgbuild') })
    let is_show = ($words | any { |w| ($w =~ '^-[a-z]*P[a-zA-Z]*$') or ($w == '--show') })
    let is_web = ($words | any { |w| ($w =~ '^-[a-z]*W[a-zA-Z]*$') or ($w == '--web') })
    let is_yay = ($words | any { |w| ($w =~ '^-[a-z]*Y[a-zA-Z]*$') or ($w == '--yay') })
    let is_files = ($words | any { |w| ($w =~ '^-[a-z]*F[a-zA-Z]*$') or ($w == '--files') })
    let is_deptest = ($words | any { |w| ($w =~ '^-[a-z]*T[a-zA-Z]*$') or ($w == '--deptest') })
    let is_help = ($words | any { |w| ($w =~ '^-[a-z]*h[a-zA-Z]*$') or ($w == '--help') })
    let is_version = ($words | any { |w| ($w =~ '^-[a-z]*V[a-zA-Z]*$') or ($w == '--version') })

    let is_owns = ($words | any { |w| ($w =~ '^-[a-zA-Z]*o[a-zA-Z]*$') or ($w == '--owns') })
    let is_file_arg = ($words | any { |w| ($w =~ '^-[a-zA-Z]*p[a-zA-Z]*$') or ($w == '--file') })
    let is_group = ($words | any { |w| ($w =~ '^-[a-zA-Z]*g[a-zA-Z]*$') or ($w == '--groups') or ($w == '--ignoregroup') })
    let is_repo_list = ($words | any { |w| ($w =~ '^-[a-zA-Z]*l[a-zA-Z]*$') or ($w == '--list') })
    let is_aur_only = ($words | any { |w| ($w =~ '^-[a-z]*a[a-zA-Z]*$') or ($w == '--aur') })
    let is_repo_only = ($words | any { |w| ($w =~ '^-[a-z]*N[a-zA-Z]*$') or ($w == '--repo') })
    let is_clean_orphans = ($words | any { |w| ($w =~ '^-[a-zA-Z]*Y[a-zA-Z]*$' and ($w =~ 'c')) or ($w == '--clean') })

    let has_operation = ($is_sync or $is_remove or $is_query or $is_database or $is_upgrade or $is_build or $is_getpkgbuild or $is_show or $is_web or $is_yay or $is_files or $is_deptest or $is_help or $is_version or $is_aur_only or $is_repo_only or $is_yaas)

    # Suggest operations when no operation is specified and user has not typed a package name
    if not $has_operation {
        if ($current == "") or ($current starts-with "-") {
            return (yay-operations)
        }
    }

    if $is_help or $is_version or $is_show {
        return []
    }

    # File completions fallback (return null so Nushell handles files)
    if $is_upgrade or $is_build or $is_owns or $is_file_arg {
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

    # Installed packages for removal, query, database, or orphan cleanup operations
    if $is_remove or $is_query or $is_database or $is_clean_orphans {
        let pkgs = (installed-pkgs)
        return (if ($prev_pkgs | is-empty) { $pkgs } else { $pkgs | where { |p| $p.value not-in $prev_pkgs } })
    }

    # All packages (repo + AUR)
    mut pkgs = (all-pkgs)

    # Filter AUR-only when -a / --aur is passed
    if $is_aur_only {
        $pkgs = ($pkgs | where description == "AUR")
    } else if $is_repo_only {
        # Filter repo-only when -N / --repo is passed
        $pkgs = ($pkgs | where description != "AUR")
    }

    # Filter already entered packages
    if ($prev_pkgs | is-empty) {
        $pkgs
    } else {
        $pkgs | where { |p| $p.value not-in $prev_pkgs }
    }
}

# Yay - Yet another Yogurt (AUR helper and Pacman wrapper)
export extern yay [
    # Main Operations
    --help(-h)                                      # Display syntax for the given operation
    --version(-V)                                   # Display version and exit
    --database(-D)                                  # Modify the package database
    --files(-F)                                     # Query the files database
    --query(-Q)                                     # Query the package database
    --remove(-R)                                    # Remove packages from the system
    --sync(-S)                                      # Synchronize packages
    --deptest(-T)                                   # Check dependencies
    --upgrade(-U)                                   # Upgrade or add a local package (.pkg.tar.zst)

    # Yay Operations
    --build(-B)                                     # Build package in current directory or specified dir
    --getpkgbuild(-G)                               # Download PKGBUILD from ABS or AUR
    --show(-P)                                      # Show statistics, config, news, or completion data
    --web(-W)                                       # Open AUR web page for target package(s)
    --yay(-Y)                                       # Yay-specific maintenance operations

    # Source Selection
    --aur(-a)                                       # Assume targets are from the AUR
    --repo(-N)                                      # Assume targets are from the repositories

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

    # Combined short flags
    -c                                              # Clean cache (-S), cascade remove (-R), changelog (-Q), or remove unneeded deps (-Y)
    -d                                              # Skip dependency checks (-S, -R, -U), list dependencies (-Q), or print default config (-P)
    -s                                              # Search databases (-S, -Q), recursive remove (-R), sync build deps (-B), or show stats (-P)
    -p                                              # Print targets (-S, -R, -U), query package file (-Q), or print PKGBUILD (-G)
    -l                                              # List packages in repo (-S) or files owned by package (-Q, -F)
    -g                                              # View package groups (-S, -Q) or print current config (-P)
    -i                                              # View package information (-S, -Q) or install built package (-B)
    -k                                              # Check database validity (-D) or verify package files (-Q)
    -m                                              # List foreign packages (-Q) or machine-readable output (-F)
    -n                                              # Ignore backup files (-R) or list native packages (-Q)
    -w                                              # Download only (-S) or print Arch news (-P)
    -f                                              # Force download for existing ABS packages (-G)
    -e                                              # Explicit packages (-Q) or edit PKGBUILD before building (-B)

    # Remove-specific options
    --cascade                                       # Remove target and all packages that depend on them
    --nosave                                        # Ignore backup (.pacsave) files
    --recursive                                     # Remove target and unused dependencies (-ss for all)
    --unneeded                                      # Remove unneeded packages
    --dbonly                                        # Only modify database entries, not package files

    # Query-specific options
    --changelog                                     # View the changelog of a package
    --deps                                          # List unrequired packages installed as dependencies
    --explicit                                      # List explicitly installed packages
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

    # Yay Build and Upgrade options
    --devel                                         # Check development packages during sysupgrade
    --rebuild                                       # Always build target packages
    --rebuildall                                    # Always build all AUR packages
    --rebuildtree                                   # Always build all AUR packages even if installed
    --norebuild                                     # Skip package build if in cache and up to date
    --redownload                                    # Always download pkgbuilds of targets
    --redownloadall                                 # Always download pkgbuilds of all AUR packages
    --noredownload                                  # Skip pkgbuild download if in cache and up to date
    --cleanmenu                                     # Give the option to clean build PKGBUILDs
    --nocleanmenu                                   # Do not show clean build menu
    --diffmenu                                      # Give the option to show diffs for build files
    --nodiffmenu                                    # Do not show diff menu
    --editmenu                                      # Give the option to edit/view PKGBUILDs
    --noeditmenu                                    # Do not show edit menu
    --answerclean: string@yay-answers               # Set predetermined answer for clean build menu
    --noanswerclean                                 # Unset answer for clean build menu
    --answerdiff: string@yay-answers                # Set predetermined answer for diff menu
    --noanswerdiff                                  # Unset answer for diff menu
    --answeredit: string@yay-answers                # Set predetermined answer for edit menu
    --noansweredit                                  # Unset answer for edit menu
    --answerupgrade: string@yay-answers             # Set predetermined answer for upgrade menu
    --noanswerupgrade                               # Unset answer for upgrade menu
    --cleanafter                                    # Remove package sources after successful install
    --keepsrc                                       # Keep pkg/ and src/ after building packages
    --topdown                                       # Show repository packages first then AUR
    --bottomup                                      # Show AUR packages first then repository
    --singlelineresults                             # List each search result on its own line
    --doublelineresults                             # List each search result on two lines (like pacman)
    --provides                                      # Look for matching providers when searching
    --pgpfetch                                      # Prompt to import PGP keys from PKGBUILDs
    --useask                                        # Automatically resolve conflicts using pacman's ask flag
    --combinedupgrade                               # Upgrade repo packages and AUR packages together
    --sudoloop                                      # Loop sudo calls in background to avoid timeout
    --gendb                                         # Generates development package DB used for updating
    --save                                          # Save options back to the config file
    --nomakepkgconf                                 # Use default makepkg.conf
    --askremovemake                                 # Ask to remove makedepends after install
    --askyesremovemake                              # Ask to remove makedepends after install ("Y" default)
    --removemake                                    # Remove makedepends after install
    --noremovemake                                  # Don't remove makedepends after install

    # Transaction options
    --needed                                        # Do not reinstall up to date packages
    --asdeps                                        # Install packages as non-explicitly installed
    --asexplicit                                    # Install packages as explicitly installed
    --noconfirm                                     # Do not ask for any confirmation
    --confirm                                       # Always ask for confirmation
    --overwrite: string                             # Overwrite conflicting files
    --assume-installed: string                      # Add a virtual package to satisfy dependencies
    --print-format: string                          # Specify how the targets should be printed
    --disable-download-timeout                      # Use relaxed timeouts for download
    --disable-sandbox                               # Disable downloader sandbox
    --noprogressbar                                 # Do not show a progress bar when downloading
    --noscriptlet                                   # Do not execute the install scriptlet if one exists

    # Configuration, search, and paths
    --cachedir: path                                # Alternate package cache location
    --color: string@color-choices                   # Colorize output (auto, always, never)
    --config: path                                  # Alternate configuration file
    --dbpath: path                                  # Alternate database location
    --root: path                                    # Alternate installation root
    --logfile: path                                 # Alternate log file
    --gpgdir: path                                  # Alternate home directory for GnuPG
    --hookdir: path                                 # Alternate hook location
    --sysroot: path                                 # Operate on a mounted guest system
    --ignore: string@all-pkgs                       # Ignore a package upgrade
    --ignoregroup: string@pkg-groups                # Ignore a group upgrade
    --sortby: string@yay-sortby                     # Sort AUR results during search
    --searchby: string@yay-searchby                 # Search AUR using specified field
    --completioninterval: int                       # Time in days to refresh completion cache
    --requestsplitn: int                            # Max amount of packages per AUR query
    --aururl: string                                # Set alternative AUR URL
    --aurrpcurl: string                             # Set alternative AUR /rpc URL
    --builddir: path                                # Directory used to download and run PKGBUILDs
    --editor: path                                  # Editor to use when editing PKGBUILDs
    --editorflags: string                           # Arguments to pass to editor
    --makepkg: path                                 # makepkg command to use
    --mflags: string                                # Arguments to pass to makepkg
    --pacman: path                                  # pacman command to use
    --git: path                                     # git command to use
    --gitflags: string                              # Arguments to pass to git
    --gpg: path                                     # gpg command to use
    --gpgflags: string                              # Arguments to pass to gpg
    --makepkgconf: path                             # makepkg.conf file to use
    --sudo: path                                    # sudo command to use
    --sudoflags: string                             # Arguments to pass to sudo

    # Positional targets
    ...targets: string@complete-yay-targets         # Packages (official repos or AUR), groups, or repositories
]
