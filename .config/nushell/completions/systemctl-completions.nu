# systemctl-completions.nu
# Custom completions for systemctl in Nushell

# Check if the execution context specifies user mode (--user or -u)
def is-user-context [context?: string] {
    let ctx = ($context | default "")
    ($ctx =~ '(^|\s)(--user|-u)(\s|$)')
}

# Return the appropriate flag list for systemctl invocations
def get-context-user-flag [context?: string] {
    if (is-user-context $context) { ["--user"] } else { [] }
}

# Subcommands supported by systemctl
export def "nu-complete systemctl subcommands" [] {
    [
        # Unit Commands
        { value: "start", description: "Start (activate) one or more units" }
        { value: "stop", description: "Stop (deactivate) one or more units" }
        { value: "restart", description: "Start or restart one or more units" }
        { value: "status", description: "Show runtime status of one or more units" }
        { value: "reload", description: "Reload one or more units" }
        { value: "try-restart", description: "Restart one or more units if active" }
        { value: "reload-or-restart", description: "Reload one or more units if possible, otherwise restart" }
        { value: "try-reload-or-restart", description: "If active, reload one or more units, otherwise restart" }
        { value: "isolate", description: "Start one unit and stop all others" }
        { value: "kill", description: "Send signal to processes of a unit" }
        { value: "clean", description: "Clean runtime, cache, state, logs or configuration of unit" }
        { value: "freeze", description: "Freeze execution of unit processes" }
        { value: "thaw", description: "Resume execution of a frozen unit" }
        { value: "is-active", description: "Check whether units are active" }
        { value: "is-failed", description: "Check whether units are failed" }
        { value: "show", description: "Show properties of one or more units/jobs" }
        { value: "cat", description: "Show files and drop-ins of specified units" }
        { value: "help", description: "Show manual for one or more units" }
        { value: "list-dependencies", description: "Recursively show units required or wanted" }
        { value: "list-units", description: "List units currently in memory" }
        { value: "list-unit-files", description: "List installed unit files" }
        { value: "list-automounts", description: "List automount units ordered by path" }
        { value: "list-paths", description: "List path units ordered by path" }
        { value: "list-sockets", description: "List socket units ordered by address" }
        { value: "list-timers", description: "List timer units ordered by next elapse" }
        { value: "list-jobs", description: "List jobs" }
        { value: "list-machines", description: "List local containers and host" }
        { value: "cancel", description: "Cancel all, one, or more jobs" }
        { value: "reset-failed", description: "Reset failed state for units" }
        { value: "service-log-level", description: "Get/set logging threshold for service" }
        { value: "service-log-target", description: "Get/set logging target for service" }
        { value: "set-property", description: "Sets one or more properties of a unit" }
        { value: "bind", description: "Bind-mount path from host into unit namespace" }
        { value: "mount-image", description: "Mount image from host into unit namespace" }
        { value: "whoami", description: "Return unit caller or specified PIDs are part of" }

        # Unit File Commands
        { value: "enable", description: "Enable one or more unit files" }
        { value: "disable", description: "Disable one or more unit files" }
        { value: "reenable", description: "Reenable one or more unit files" }
        { value: "preset", description: "Enable/disable unit files based on preset" }
        { value: "preset-all", description: "Enable/disable all unit files based on preset" }
        { value: "is-enabled", description: "Check whether unit files are enabled" }
        { value: "mask", description: "Mask one or more units" }
        { value: "unmask", description: "Unmask one or more units" }
        { value: "link", description: "Link one or more unit files into search path" }
        { value: "revert", description: "Revert one or more unit files to vendor version" }
        { value: "add-wants", description: "Add 'Wants' dependency for target" }
        { value: "add-requires", description: "Add 'Requires' dependency for target" }
        { value: "edit", description: "Edit one or more unit files" }
        { value: "get-default", description: "Get the default target" }
        { value: "set-default", description: "Set the default target" }

        # Environment Commands
        { value: "show-environment", description: "Dump environment" }
        { value: "set-environment", description: "Set one or more environment variables" }
        { value: "unset-environment", description: "Unset one or more environment variables" }
        { value: "import-environment", description: "Import all or some environment variables" }

        # Manager State Commands
        { value: "daemon-reload", description: "Reload systemd manager configuration" }
        { value: "daemon-reexec", description: "Reexecute systemd manager" }
        { value: "log-level", description: "Get/set logging threshold for manager" }
        { value: "log-target", description: "Get/set logging target for manager" }
        { value: "service-watchdogs", description: "Get/set service watchdog state" }

        # System Commands
        { value: "is-system-running", description: "Check whether system is fully running" }
        { value: "default", description: "Enter system default mode" }
        { value: "rescue", description: "Enter system rescue mode" }
        { value: "emergency", description: "Enter system emergency mode" }
        { value: "halt", description: "Shut down and halt the system" }
        { value: "poweroff", description: "Shut down and power-off the system" }
        { value: "reboot", description: "Shut down and reboot the system" }
        { value: "kexec", description: "Shut down and reboot with kexec" }
        { value: "soft-reboot", description: "Shut down and reboot userspace" }
        { value: "exit", description: "Request user instance or container exit" }
        { value: "switch-root", description: "Change to a different root file system" }
        { value: "sleep", description: "Put the system to sleep" }
        { value: "suspend", description: "Suspend the system" }
        { value: "hibernate", description: "Hibernate the system" }
        { value: "hybrid-sleep", description: "Hibernate and suspend the system" }
        { value: "suspend-then-hibernate", description: "Suspend the system then hibernate" }
    ]
}

# Complete all units (loaded units in memory + unit files on disk)
export def "nu-complete systemctl all-units" [context?: string] {
    let user_flag = (get-context-user-flag $context)
    let is_user = (is-user-context $context)

    let loaded = (try {
        ^systemctl ...$user_flag list-units --all --output=json
        | from json
        | where not ($it.unit ends-with ".device")
        | each { |u|
            let desc = if ($u.description? | is-not-empty) {
                $"($u.active) \(($u.sub)\) - ($u.description)"
            } else {
                $"($u.active) \(($u.sub)\)"
            }
            { value: $u.unit, description: $desc }
        }
    } catch { [] })

    let dirs = if $is_user {
        [
            ($env.HOME | path join ".config/systemd/user"),
            "/etc/systemd/user",
            "/usr/lib/systemd/user"
        ]
    } else {
        [
            "/etc/systemd/system",
            "/run/systemd/system",
            "/usr/lib/systemd/system"
        ]
    }

    let disk = (
        $dirs
        | where { |p| $p | path exists }
        | each { |p| glob $"($p)/*.{service,socket,target,timer,path,mount,automount,slice,scope}" }
        | flatten
        | each { |p| $p | path basename }
        | uniq
        | each { |name| { value: $name, description: "unit file" } }
    )

    $loaded | append $disk | uniq-by value
}

# Complete active / activating / failed units (for stop, kill, freeze, thaw)
export def "nu-complete systemctl active-units" [context?: string] {
    let user_flag = (get-context-user-flag $context)
    try {
        ^systemctl ...$user_flag list-units --state=active,activating,reloading,failed --output=json
        | from json
        | where not ($it.unit ends-with ".device")
        | each { |u|
            let desc = if ($u.description? | is-not-empty) {
                $"($u.active) \(($u.sub)\) - ($u.description)"
            } else {
                $"($u.active) \(($u.sub)\)"
            }
            { value: $u.unit, description: $desc }
        }
    } catch { [] }
}

# Complete all installed unit files (for enable, reenable, preset, edit, revert)
export def "nu-complete systemctl all-unit-files" [context?: string] {
    let user_flag = (get-context-user-flag $context)
    let files = (try {
        ^systemctl ...$user_flag list-unit-files --output=json
        | from json
        | where not ($it.unit_file ends-with ".device")
        | each { |u|
            let state = ($u.state? | default "unknown")
            { value: $u.unit_file, description: $"unit file \(($state)\)" }
        }
    } catch { [] })
    if ($files | is-not-empty) {
        $files
    } else {
        nu-complete systemctl all-units $context
    }
}

# Complete currently enabled unit files (for disable)
export def "nu-complete systemctl enabled-unit-files" [context?: string] {
    let user_flag = (get-context-user-flag $context)
    let files = (try {
        ^systemctl ...$user_flag list-unit-files --state=enabled,enabled-runtime,linked,linked-runtime,alias --output=json
        | from json
        | where not ($it.unit_file ends-with ".device")
        | each { |u|
            let state = ($u.state? | default "enabled")
            { value: $u.unit_file, description: $"($state)" }
        }
    } catch { [] })
    if ($files | is-not-empty) {
        $files
    } else {
        nu-complete systemctl all-units $context
    }
}

# Complete currently masked unit files (for unmask)
export def "nu-complete systemctl masked-unit-files" [context?: string] {
    let user_flag = (get-context-user-flag $context)
    let files = (try {
        ^systemctl ...$user_flag list-unit-files --state=masked,masked-runtime --output=json
        | from json
        | where not ($it.unit_file ends-with ".device")
        | each { |u|
            let state = ($u.state? | default "masked")
            { value: $u.unit_file, description: $"($state)" }
        }
    } catch { [] })
    if ($files | is-not-empty) {
        $files
    } else {
        nu-complete systemctl all-units $context
    }
}

# Complete target units (for isolate, set-default, add-wants, add-requires)
export def "nu-complete systemctl target-units" [context?: string] {
    let user_flag = (get-context-user-flag $context)
    try {
        ^systemctl ...$user_flag list-units --type=target --all --output=json
        | from json
        | where not ($it.unit starts-with "blockdev@")
        | each { |u|
            let desc = if ($u.description? | is-not-empty) {
                $"target - ($u.description)"
            } else {
                "target"
            }
            { value: $u.unit, description: $desc }
        }
    } catch { [] }
}

# Complete failed units (for is-failed, reset-failed)
export def "nu-complete systemctl failed-units" [context?: string] {
    let user_flag = (get-context-user-flag $context)
    let failed = (try {
        ^systemctl ...$user_flag list-units --state=failed --output=json
        | from json
        | each { |u|
            let desc = if ($u.description? | is-not-empty) {
                $"failed - ($u.description)"
            } else {
                "failed"
            }
            { value: $u.unit, description: $desc }
        }
    } catch { [] })
    if ($failed | is-not-empty) {
        $failed
    } else {
        nu-complete systemctl all-units $context
    }
}

# Complete active job IDs (for cancel)
export def "nu-complete systemctl jobs" [context?: string] {
    let user_flag = (get-context-user-flag $context)
    try {
        ^systemctl ...$user_flag list-jobs --output=json
        | from json
        | each { |j|
            {
                value: ($j.job | into string),
                description: $"($j.unit) \(($j.type) ($j.state)\)"
            }
        }
    } catch { [] }
}

# Unit types
export def "nu-complete systemctl unit-types" [] {
    [
        { value: "service", description: "Service unit" }
        { value: "socket", description: "Socket unit" }
        { value: "target", description: "Target unit" }
        { value: "device", description: "Device unit" }
        { value: "mount", description: "Mount unit" }
        { value: "automount", description: "Automount unit" }
        { value: "timer", description: "Timer unit" }
        { value: "path", description: "Path unit" }
        { value: "slice", description: "Slice unit" }
        { value: "scope", description: "Scope unit" }
        { value: "swap", description: "Swap unit" }
    ]
}

# Unit states
export def "nu-complete systemctl unit-states" [] {
    [
        "active"
        "reloading"
        "inactive"
        "failed"
        "activating"
        "deactivating"
        "loaded"
        "not-found"
        "bad-setting"
        "error"
        "masked"
    ]
}

# Signals for systemctl kill
export def "nu-complete systemctl signals" [] {
    [
        "SIGTERM"
        "SIGKILL"
        "SIGHUP"
        "SIGINT"
        "SIGUSR1"
        "SIGUSR2"
        "SIGCONT"
        "SIGSTOP"
        "SIGABRT"
        "SIGQUIT"
        "SIGPIPE"
        "SIGALRM"
    ]
}

# Log levels
export def "nu-complete systemctl log-levels" [] {
    ["emerg", "alert", "crit", "err", "warning", "notice", "info", "debug"]
}

# Log targets
export def "nu-complete systemctl log-targets" [] {
    ["console", "journal", "kmsg", "journal-or-kmsg", "syslog", "null"]
}

# Clean resources
export def "nu-complete systemctl clean-what" [] {
    [
        { value: "runtime", description: "Runtime data" }
        { value: "cache", description: "Cache data" }
        { value: "state", description: "Persistent state" }
        { value: "logs", description: "Log data" }
        { value: "configuration", description: "Configuration data" }
        { value: "all", description: "All resource types" }
    ]
}

# Output formats
export def "nu-complete systemctl output-formats" [] {
    [
        "short"
        "short-precise"
        "short-iso"
        "short-iso-precise"
        "short-full"
        "short-monotonic"
        "short-unix"
        "short-delta"
        "verbose"
        "export"
        "json"
        "json-pretty"
        "json-sse"
        "cat"
    ]
}

# Kill targets
export def "nu-complete systemctl kill-who" [] {
    ["all", "main", "control"]
}

# Job modes
export def "nu-complete systemctl job-modes" [] {
    ["fail", "replace", "replace-irreversibly", "isolate", "ignore-dependencies", "ignore-requirements", "flush"]
}

# Dynamic positional arguments completer for `systemctl` base command
# Dispatches based on the subcommand in the context line
export def "nu-complete systemctl dynamic-args" [context?: string] {
    let ctx = ($context | default "")
    let words = ($ctx | split row -r '\s+' | where { |w|
        not ($w starts-with "-") and ($w != "systemctl") and ($w != "^systemctl") and ($w | is-not-empty)
    })
    let subcmd = ($words.0? | default "")
    match $subcmd {
        "stop" | "kill" | "freeze" | "thaw" => { nu-complete systemctl active-units $ctx }
        "start" => { nu-complete systemctl all-units $ctx }
        "restart" | "reload" | "try-restart" | "reload-or-restart" | "try-reload-or-restart" => { nu-complete systemctl all-units $ctx }
        "status" | "is-active" | "show" | "cat" | "help" | "list-dependencies" => { nu-complete systemctl all-units $ctx }
        "is-failed" | "reset-failed" => { nu-complete systemctl failed-units $ctx }
        "enable" | "reenable" | "preset" => { nu-complete systemctl all-unit-files $ctx }
        "disable" => { nu-complete systemctl enabled-unit-files $ctx }
        "mask" => { nu-complete systemctl all-units $ctx }
        "unmask" => { nu-complete systemctl masked-unit-files $ctx }
        "edit" | "revert" => { nu-complete systemctl all-unit-files $ctx }
        "isolate" | "set-default" => { nu-complete systemctl target-units $ctx }
        "cancel" => { nu-complete systemctl jobs $ctx }
        "clean" => { nu-complete systemctl all-units $ctx }
        "service-log-level" | "service-log-target" => { nu-complete systemctl all-units $ctx }
        _ => { nu-complete systemctl all-units $ctx }
    }
}

# Base systemctl command signature
export extern "systemctl" [
    subcommand?: string@"nu-complete systemctl subcommands" # Systemctl command to execute
    ...args: string@"nu-complete systemctl dynamic-args"    # Arguments to the command
    --help(-h)                                              # Show help text
    --version                                               # Show package version
    --system                                                # Connect to system service manager
    --user(-u)                                              # Connect to user service manager
    --all(-a)                                               # Show all properties/all units currently in memory
    --full(-l)                                              # Don't ellipsize unit names on output
    --type(-t): string@"nu-complete systemctl unit-types"    # List units of a particular type
    --state: string@"nu-complete systemctl unit-states"     # List units with particular LOAD or SUB or ACTIVE state
    --failed                                                # Shortcut for --state=failed
    --property(-p): string                                  # Show only properties by this name
    -P: string                                              # Equivalent to --value --property=NAME
    --value                                                 # When showing properties, only print the value
    --quiet(-q)                                             # Suppress output
    --verbose(-v)                                           # Show unit logs while executing operation
    --no-block                                              # Do not wait until operation finished
    --wait                                                  # Wait until service stopped again or startup completed
    --now                                                   # Start or stop unit after enabling or disabling it
    --runtime                                               # Enable/disable/mask unit files temporarily until next reboot
    --global                                                # Enable/disable/mask default user unit files globally
    --force(-f)                                             # When enabling, override existing symlinks; when shutting down, execute immediately
    --no-pager                                              # Do not start a pager
    --no-legend                                             # Do not print header and hints
    --no-ask-password                                       # Do not prompt for password
    --lines(-n): int                                        # Number of journal entries to show
    --output(-o): string@"nu-complete systemctl output-formats" # Change journal output mode
    --signal(-s): string@"nu-complete systemctl signals"    # Which signal to send
    --kill-whom: string@"nu-complete systemctl kill-who"    # Whom to send signal to
    --what: string@"nu-complete systemctl clean-what"       # Which types of resources to remove
    --job-mode: string@"nu-complete systemctl job-modes"    # How to deal with already queued jobs
    --host(-H): string                                      # Operate on remote host
    --machine(-M): string                                   # Operate on local container
]

# Start (activate) one or more units
export extern "systemctl start" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to start
    --all(-a)                                               # Start all matching units
    --no-block                                              # Do not wait until operation finished
    --wait                                                  # Wait until service stopped again
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
    --host(-H): string                                      # Operate on remote host
    --machine(-M): string                                   # Operate on local container
]

# Stop (deactivate) one or more units
export extern "systemctl stop" [
    ...units: string@"nu-complete systemctl active-units"   # Unit(s) to stop
    --all(-a)                                               # Stop all matching units
    --no-block                                              # Do not wait until operation finished
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
    --host(-H): string                                      # Operate on remote host
    --machine(-M): string                                   # Operate on local container
]

# Start or restart one or more units
export extern "systemctl restart" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to restart
    --all(-a)                                               # Restart all matching units
    --no-block                                              # Do not wait until operation finished
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
    --host(-H): string                                      # Operate on remote host
    --machine(-M): string                                   # Operate on local container
]

# Reload one or more units
export extern "systemctl reload" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to reload
    --no-block                                              # Do not wait until operation finished
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
    --host(-H): string                                      # Operate on remote host
    --machine(-M): string                                   # Operate on local container
]

# Restart one or more units if active
export extern "systemctl try-restart" [
    ...units: string@"nu-complete systemctl active-units"   # Unit(s) to try restart
    --no-block                                              # Do not wait until operation finished
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
]

# Reload one or more units if possible, otherwise start or restart
export extern "systemctl reload-or-restart" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to reload or restart
    --no-block                                              # Do not wait until operation finished
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
]

# If active, reload one or more units, otherwise restart
export extern "systemctl try-reload-or-restart" [
    ...units: string@"nu-complete systemctl active-units"   # Unit(s) to try reload or restart
    --no-block                                              # Do not wait until operation finished
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
]

# Show runtime status of one or more units
export extern "systemctl status" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) or PID(s) to show status for
    --all(-a)                                               # Show all properties/units
    --full(-l)                                              # Don't ellipsize unit names on output
    --lines(-n): int                                        # Number of journal entries to show
    --output(-o): string@"nu-complete systemctl output-formats" # Change journal output mode
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --no-pager                                              # Do not start a pager
    --host(-H): string                                      # Operate on remote host
    --machine(-M): string                                   # Operate on local container
]

# Check whether units are active
export extern "systemctl is-active" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to check
    --quiet(-q)                                             # Suppress output
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Check whether units are failed
export extern "systemctl is-failed" [
    ...units: string@"nu-complete systemctl failed-units"   # Unit(s) to check
    --quiet(-q)                                             # Suppress output
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Check whether unit files are enabled
export extern "systemctl is-enabled" [
    ...units: string@"nu-complete systemctl all-unit-files" # Unit file(s) to check
    --quiet(-q)                                             # Suppress output
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Enable one or more unit files
export extern "systemctl enable" [
    ...units: string@"nu-complete systemctl all-unit-files" # Unit file(s) to enable
    --now                                                   # Start unit after enabling
    --runtime                                               # Enable temporarily until next reboot
    --force(-f)                                             # Override existing symlinks
    --global                                                # Enable user unit files globally
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
]

# Disable one or more unit files
export extern "systemctl disable" [
    ...units: string@"nu-complete systemctl enabled-unit-files" # Unit file(s) to disable
    --now                                                   # Stop unit after disabling
    --runtime                                               # Disable temporarily until next reboot
    --global                                                # Disable user unit files globally
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
]

# Reenable one or more unit files
export extern "systemctl reenable" [
    ...units: string@"nu-complete systemctl all-unit-files" # Unit file(s) to reenable
    --now                                                   # Restart unit after reenabling
    --runtime                                               # Reenable temporarily until next reboot
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --quiet(-q)                                             # Suppress output
]

# Mask one or more units
export extern "systemctl mask" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to mask
    --now                                                   # Stop unit after masking
    --runtime                                               # Mask temporarily until next reboot
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Unmask one or more units
export extern "systemctl unmask" [
    ...units: string@"nu-complete systemctl masked-unit-files" # Unit(s) to unmask
    --runtime                                               # Unmask runtime links
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Show properties of one or more units/jobs or the manager
export extern "systemctl show" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to show properties for
    --property(-p): string                                  # Show only properties by this name
    -P: string                                              # Equivalent to --value --property=NAME
    --value                                                 # Only print property values
    --all(-a)                                               # Show all properties
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Show files and drop-ins of specified units
export extern "systemctl cat" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to show
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Edit one or more unit files
export extern "systemctl edit" [
    ...units: string@"nu-complete systemctl all-unit-files" # Unit file(s) to edit
    --runtime                                               # Edit temporarily until next reboot
    --full                                                  # Create/edit full replacement instead of drop-in
    --global                                                # Edit user unit files globally
    --drop-in: string                                       # Specify drop-in file name
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Revert one or more unit files to vendor version
export extern "systemctl revert" [
    ...units: string@"nu-complete systemctl all-unit-files" # Unit file(s) to revert
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Send signal to processes of a unit
export extern "systemctl kill" [
    ...units: string@"nu-complete systemctl active-units"   # Unit(s) to kill
    --signal(-s): string@"nu-complete systemctl signals"    # Signal to send
    --kill-whom: string@"nu-complete systemctl kill-who"    # Whom to send signal to
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Clean runtime, cache, state, logs or configuration of unit
export extern "systemctl clean" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to clean
    --what: string@"nu-complete systemctl clean-what"       # Resource types to remove
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Start one unit and stop all others
export extern "systemctl isolate" [
    unit: string@"nu-complete systemctl target-units"       # Target unit to isolate
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Set the default target
export extern "systemctl set-default" [
    target: string@"nu-complete systemctl target-units"     # Target unit to set as default
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Get the default target
export extern "systemctl get-default" [
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Reset failed state for all, one, or more units
export extern "systemctl reset-failed" [
    ...units: string@"nu-complete systemctl failed-units"   # Unit(s) to reset
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Reload systemd manager configuration
export extern "systemctl daemon-reload" [
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Reexecute systemd manager
export extern "systemctl daemon-reexec" [
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# List units currently in memory
export extern "systemctl list-units" [
    ...pattern: string                                      # Unit name pattern
    --type(-t): string@"nu-complete systemctl unit-types"   # List units of a particular type
    --state: string@"nu-complete systemctl unit-states"    # List units with particular state
    --all(-a)                                               # Show all loaded units
    --failed                                                # Shortcut for --state=failed
    --full(-l)                                              # Don't ellipsize unit names
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --no-pager                                              # Do not start a pager
    --no-legend                                             # Do not print header/hints
]

# List installed unit files
export extern "systemctl list-unit-files" [
    ...pattern: string                                      # Unit name pattern
    --type(-t): string@"nu-complete systemctl unit-types"   # List units of a particular type
    --state: string@"nu-complete systemctl unit-states"    # List unit files with particular state
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
    --no-pager                                              # Do not start a pager
    --no-legend                                             # Do not print header/hints
]

# List timer units currently in memory, ordered by next elapse
export extern "systemctl list-timers" [
    ...pattern: string                                      # Timer pattern
    --all(-a)                                               # Show inactive timers too
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# List socket units currently in memory, ordered by address
export extern "systemctl list-sockets" [
    ...pattern: string                                      # Socket pattern
    --all(-a)                                               # Show inactive sockets too
    --show-types                                            # Explicitly show socket types
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Recursively show units which are required or wanted
export extern "systemctl list-dependencies" [
    ...units: string@"nu-complete systemctl all-units"      # Unit(s) to inspect
    --reverse                                               # Show reverse dependencies
    --before                                                # Show units ordered before
    --after                                                 # Show units ordered after
    --plain                                                 # Print dependencies as a list instead of a tree
    --all(-a)                                               # Do not ellipsize
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Cancel all, one, or more jobs
export extern "systemctl cancel" [
    ...jobs: string@"nu-complete systemctl jobs"            # Job ID(s) to cancel
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Dump environment
export extern "systemctl show-environment" [
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]

# Check whether system is fully running
export extern "systemctl is-system-running" [
    --quiet(-q)                                             # Suppress output
    --wait                                                  # Wait until startup completed
    --user(-u)                                              # Connect to user service manager
    --system                                                # Connect to system service manager
]
