# pkill-completions.nu
# Custom completions for pkill and pgrep in Nushell

# Complete signals by name or standard number
def "nu-complete pkill signals" [] {
  [
    { value: "SIGTERM",  description: "Termination signal (default, 15)" }
    { value: "TERM",     description: "Termination signal (default, 15)" }
    { value: "15",       description: "Termination signal (SIGTERM)" }
    { value: "SIGKILL",  description: "Kill signal, uncatchable (9)" }
    { value: "KILL",     description: "Kill signal, uncatchable (9)" }
    { value: "9",        description: "Kill signal (SIGKILL)" }
    { value: "SIGHUP",   description: "Hangup detected or config reload (1)" }
    { value: "HUP",      description: "Hangup detected or config reload (1)" }
    { value: "1",        description: "Hangup (SIGHUP)" }
    { value: "SIGINT",   description: "Interrupt from keyboard, Ctrl+C (2)" }
    { value: "INT",      description: "Interrupt from keyboard, Ctrl+C (2)" }
    { value: "2",        description: "Interrupt (SIGINT)" }
    { value: "SIGQUIT",  description: "Quit from keyboard, core dump (3)" }
    { value: "QUIT",     description: "Quit from keyboard, core dump (3)" }
    { value: "3",        description: "Quit (SIGQUIT)" }
    { value: "SIGSTOP",  description: "Stop process execution, uncatchable (19)" }
    { value: "STOP",     description: "Stop process execution, uncatchable (19)" }
    { value: "19",       description: "Stop process execution (SIGSTOP)" }
    { value: "SIGCONT",  description: "Continue process if stopped (18)" }
    { value: "CONT",     description: "Continue process if stopped (18)" }
    { value: "18",       description: "Continue process (SIGCONT)" }
    { value: "SIGUSR1",  description: "User-defined signal 1 (10)" }
    { value: "USR1",     description: "User-defined signal 1 (10)" }
    { value: "10",       description: "User-defined signal 1 (SIGUSR1)" }
    { value: "SIGUSR2",  description: "User-defined signal 2 (12)" }
    { value: "USR2",     description: "User-defined signal 2 (12)" }
    { value: "12",       description: "User-defined signal 2 (SIGUSR2)" }
    { value: "SIGWINCH", description: "Window resize signal (28)" }
    { value: "WINCH",    description: "Window resize signal (28)" }
    { value: "28",       description: "Window resize (SIGWINCH)" }
    { value: "SIGTSTP",  description: "Terminal stop signal, Ctrl+Z (20)" }
    { value: "TSTP",     description: "Terminal stop signal, Ctrl+Z (20)" }
    { value: "20",       description: "Terminal stop (SIGTSTP)" }
    { value: "SIGABRT",  description: "Abort signal from abort() (6)" }
    { value: "ABRT",     description: "Abort signal from abort() (6)" }
    { value: "6",        description: "Abort (SIGABRT)" }
    { value: "SIGALRM",  description: "Timer signal from alarm() (14)" }
    { value: "ALRM",     description: "Timer signal from alarm() (14)" }
    { value: "14",       description: "Timer signal (SIGALRM)" }
    { value: "SIGPIPE",  description: "Broken pipe: write with no readers (13)" }
    { value: "PIPE",     description: "Broken pipe: write with no readers (13)" }
    { value: "13",       description: "Broken pipe (SIGPIPE)" }
    { value: "SIGCHLD",  description: "Child process stopped or terminated (17)" }
    { value: "CHLD",     description: "Child process stopped or terminated (17)" }
    { value: "17",       description: "Child status changed (SIGCHLD)" }
    { value: "SIGILL",   description: "Illegal instruction (4)" }
    { value: "ILL",      description: "Illegal instruction (4)" }
    { value: "4",        description: "Illegal instruction (SIGILL)" }
    { value: "SIGTRAP",  description: "Trace / breakpoint trap (5)" }
    { value: "TRAP",     description: "Trace / breakpoint trap (5)" }
    { value: "5",        description: "Trace trap (SIGTRAP)" }
    { value: "SIGBUS",   description: "Bus error: memory access alignment (7)" }
    { value: "BUS",      description: "Bus error (SIGBUS)" }
    { value: "7",        description: "Bus error (SIGBUS)" }
    { value: "SIGFPE",   description: "Floating-point exception (8)" }
    { value: "FPE",      description: "Floating-point exception (8)" }
    { value: "8",        description: "Floating-point exception (SIGFPE)" }
    { value: "SIGSEGV",  description: "Segmentation violation (11)" }
    { value: "SEGV",     description: "Segmentation violation (11)" }
    { value: "11",       description: "Segmentation violation (SIGSEGV)" }
    { value: "SIGURG",   description: "Urgent condition on socket (23)" }
    { value: "URG",      description: "Urgent condition on socket (23)" }
    { value: "23",       description: "Urgent condition (SIGURG)" }
    { value: "SIGXCPU",  description: "CPU time limit exceeded (24)" }
    { value: "XCPU",     description: "CPU time limit exceeded (24)" }
    { value: "24",       description: "CPU time limit exceeded (SIGXCPU)" }
    { value: "SIGXFSZ",  description: "File size limit exceeded (25)" }
    { value: "XFSZ",     description: "File size limit exceeded (25)" }
    { value: "25",       description: "File size limit exceeded (SIGXFSZ)" }
    { value: "SIGVTALRM",description: "Virtual timer expired (26)" }
    { value: "VTALRM",   description: "Virtual timer expired (26)" }
    { value: "26",       description: "Virtual timer expired (SIGVTALRM)" }
    { value: "SIGPROF",  description: "Profiling timer expired (27)" }
    { value: "PROF",     description: "Profiling timer expired (27)" }
    { value: "27",       description: "Profiling timer expired (SIGPROF)" }
    { value: "SIGIO",    description: "I/O now possible (29)" }
    { value: "IO",       description: "I/O now possible (29)" }
    { value: "29",       description: "I/O possible (SIGIO)" }
    { value: "SIGPWR",   description: "Power failure (30)" }
    { value: "PWR",      description: "Power failure (30)" }
    { value: "30",       description: "Power failure (SIGPWR)" }
    { value: "SIGSYS",   description: "Bad system call (31)" }
    { value: "SYS",      description: "Bad system call (31)" }
    { value: "31",       description: "Bad system call (SIGSYS)" }
    { value: "0",        description: "Check process existence (null signal)" }
  ]
}

# Complete user accounts from /etc/passwd
def "nu-complete pkill users" [] {
  try {
    open /etc/passwd
    | lines
    | parse -r '^(?P<user>[^:]+):[^:]*:(?P<uid>\d+):'
    | each { |it| { value: $it.user, description: $"UID ($it.uid)" } }
    | sort-by value
  } catch {
    []
  }
}

# Complete groups from /etc/group
def "nu-complete pkill groups" [] {
  try {
    open /etc/group
    | lines
    | parse -r '^(?P<group>[^:]+):[^:]*:(?P<gid>\d+):'
    | each { |it| { value: $it.group, description: $"GID ($it.gid)" } }
    | sort-by value
  } catch {
    []
  }
}

# Complete process run states
def "nu-complete pkill runstates" [] {
  [
    { value: "D", description: "Uninterruptible sleep (usually IO)" }
    { value: "R", description: "Running or runnable (on run queue)" }
    { value: "S", description: "Interruptible sleep (waiting for event)" }
    { value: "T", description: "Stopped by job control signal" }
    { value: "t", description: "Stopped by debugger during trace" }
    { value: "X", description: "Dead (should never be seen)" }
    { value: "Z", description: "Defunct (zombie) process" }
  ]
}

# Complete namespace types
def "nu-complete pkill namespaces" [] {
  [
    { value: "ipc",  description: "System V IPC and POSIX message queues" }
    { value: "mnt",  description: "Mount namespace (file system mount points)" }
    { value: "net",  description: "Network devices, stacks, ports, etc." }
    { value: "pid",  description: "Process IDs" }
    { value: "user", description: "User and group IDs" }
    { value: "uts",  description: "Host name and NIS domain name" }
  ]
}

# Complete active controlling terminals (ttys)
def "nu-complete pkill ttys" [] {
  try {
    ^ps -eo tty=
    | lines
    | str trim
    | where $it != "?" and $it != ""
    | uniq
  } catch {
    []
  }
}

# Complete active process IDs
def "nu-complete pkill pids" [] {
  try {
    ^ps -eo pid=,ppid=,user=,comm=
    | lines
    | parse -r '^\s*(?P<pid>\d+)\s+(?P<ppid>\d+)\s+(?P<user>\S+)\s+(?P<comm>.*)$'
    | where ppid != "2" and pid != "2"
    | each { |it| { value: $it.pid, description: $"($it.comm) [($it.user)]" } }
  } catch {
    []
  }
}

# Complete running process names, context-aware (filters by user if -u/--euid/-U/--uid is given)
def "nu-complete pkill process names" [context?: string] {
  try {
    let ctx = ($context | default "")
    let filter_user = ($ctx | parse -r '(?:\s|^)(?:-u|--euid|-U|--uid)\s+(?P<user>\S+)' | get -o 0.user)

    let procs = (^ps -eo pid=,ppid=,user=,comm=,args=
      | lines
      | parse -r '^\s*(?P<pid>\d+)\s+(?P<ppid>\d+)\s+(?P<user>\S+)\s+(?P<comm>\S+)\s+(?P<args>.*)$'
      | where ppid != "2" and pid != "2"
    )

    let filtered = if ($filter_user != null and $filter_user != "") {
      $procs | where user == $filter_user
    } else {
      $procs
    }

    $filtered
    | group-by comm
    | transpose comm group
    | each { |it|
        let cnt = ($it.group | length)
        let pids = ($it.group | get pid | first 3 | str join ", ")
        let user = ($it.group | get user | first)
        let desc = if $cnt > 1 {
          $"($cnt) procs [($user)] PIDs: ($pids)..."
        } else {
          let a = ($it.group | first | get args | str trim)
          let a_trunc = if ($a | str length) > 50 { $"($a | str substring 0..50)..." } else { $a }
          $"PID ($pids) [($user)] ($a_trunc)"
        }
        { value: $it.comm, description: $desc }
      }
    | sort-by value
  } catch {
    []
  }
}

# Signal processes by name or attributes
export extern "pkill" [
  pattern?: string@"nu-complete pkill process names"    # Process name pattern to match
  --signal: string@"nu-complete pkill signals"           # Signal to send (number or name)
  -9                                                    # Send SIGKILL (kill immediately, force)
  -1                                                    # Send SIGHUP (hangup / reload)
  -2                                                    # Send SIGINT (interrupt / Ctrl+C)
  -3                                                    # Send SIGQUIT (quit / dump core)
  -6                                                    # Send SIGABRT (abort)
  --echo(-e)                                            # Display what is killed
  --count(-c)                                           # Display count of matching processes
  --full(-f)                                            # Use full command line to match
  --exact(-x)                                           # Match exactly with the command name
  --ignore-case(-i)                                     # Match case insensitively
  --newest(-n)                                          # Select most recently started
  --oldest(-o)                                          # Select least recently started
  --older(-O): int                                      # Select processes older than seconds
  --pid(-p): string@"nu-complete pkill pids"            # Match process PIDs (comma-separated list)
  --parent(-P): string@"nu-complete pkill pids"         # Match only child processes of given parent
  --pgroup(-g): string                                  # Match listed process group IDs
  --group(-G): string@"nu-complete pkill groups"        # Match real group IDs or names
  --session(-s): string                                 # Match session IDs
  --terminal(-t): string@"nu-complete pkill ttys"       # Match by controlling terminal
  --euid(-u): string@"nu-complete pkill users"          # Match by effective user IDs or names
  --uid(-U): string@"nu-complete pkill users"           # Match by real user IDs or names
  --pidfile(-F): path                                   # Read PIDs from file
  --logpidfile(-L)                                      # Fail if PID file is not locked
  --runstates(-r): string@"nu-complete pkill runstates" # Match runstates (D, R, S, T, t, X, Z)
  --ignore-ancestors(-A)                                # Exclude our ancestors from results
  --require-handler(-H)                                 # Match only if signal handler is present
  --mrelease(-m)                                        # Release process memory immediately after kill
  --queue(-q): int                                      # Integer value to be sent with signal
  --shell-quote(-Q)                                     # Output command line in shell-quoted form
  --cgroup: string                                      # Match by cgroup v2 names
  --ns: int                                             # Match processes in same namespace as PID
  --nslist: string@"nu-complete pkill namespaces"       # Namespaces to consider (ipc, mnt, net, pid, user, uts)
  --env: string                                         # Match on environment variable (NAME=val)
  --help(-h)                                            # Display help and exit
  --version(-V)                                         # Output version information and exit
]

# Look up processes based on name and attributes
export extern "pgrep" [
  pattern?: string@"nu-complete pkill process names"    # Process name pattern to match
  --signal: string@"nu-complete pkill signals"           # Filter by signal handler (with -H)
  --list-name(-l)                                       # List PID and process name
  --list-full(-a)                                       # List PID and full command line
  --delimiter(-d): string                               # Specify output delimiter
  --count(-c)                                           # Display count of matching processes
  --full(-f)                                            # Use full command line to match
  --exact(-x)                                           # Match exactly with the command name
  --ignore-case(-i)                                     # Match case insensitively
  --inverse(-v)                                         # Negate the matching
  --lightweight(-w)                                     # List all TID
  --quiet                                               # Suppress all normal output
  --newest(-n)                                          # Select most recently started
  --oldest(-o)                                          # Select least recently started
  --older(-O): int                                      # Select processes older than seconds
  --pid(-p): string@"nu-complete pkill pids"            # Match process PIDs (comma-separated list)
  --parent(-P): string@"nu-complete pkill pids"         # Match only child processes of given parent
  --pgroup(-g): string                                  # Match listed process group IDs
  --group(-G): string@"nu-complete pkill groups"        # Match real group IDs or names
  --session(-s): string                                 # Match session IDs
  --terminal(-t): string@"nu-complete pkill ttys"       # Match by controlling terminal
  --euid(-u): string@"nu-complete pkill users"          # Match by effective user IDs or names
  --uid(-U): string@"nu-complete pkill users"           # Match by real user IDs or names
  --pidfile(-F): path                                   # Read PIDs from file
  --logpidfile(-L)                                      # Fail if PID file is not locked
  --runstates(-r): string@"nu-complete pkill runstates" # Match runstates (D, R, S, T, t, X, Z)
  --ignore-ancestors(-A)                                # Exclude our ancestors from results
  --require-handler(-H)                                 # Match only if signal handler is present
  --shell-quote(-Q)                                     # Output command line in shell-quoted form
  --cgroup: string                                      # Match by cgroup v2 names
  --ns: int                                             # Match processes in same namespace as PID
  --nslist: string@"nu-complete pkill namespaces"       # Namespaces to consider (ipc, mnt, net, pid, user, uts)
  --env: string                                         # Match on environment variable (NAME=val)
  --help(-h)                                            # Display help and exit
  --version(-V)                                         # Output version information and exit
]
