# docker-compose-completions.nu - Native completions for standalone docker-compose
# Supports all compose subcommands, flags, and service completions

def "nu-complete docker-compose services" [] {
  let out = (do { ^docker compose config --services } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines | where $it != ""
  } else {
    []
  }
}

def "nu-complete docker-compose service status" [] {
  [paused, restarting, removing, running, dead, created, exited]
}

def "nu-complete docker-compose pull policies" [] {
  [always, missing, never]
}

def "nu-complete docker-compose extern-subcommands" [] {
  [
    "attach", "bridge", "build", "commit", "config", "cp", "create", "down",
    "events", "exec", "export", "images", "kill", "logs", "ls", "pause",
    "port", "ps", "publish", "pull", "push", "restart", "rm", "run", "scale",
    "start", "stats", "stop", "top", "unpause", "up", "version", "volumes",
    "wait", "watch"
  ]
}

def "nu-complete docker-compose subcommands-fallback" [] {
  let known = (nu-complete docker-compose extern-subcommands)
  let out = (do { ^docker compose --help } | complete)
  if $out.exit_code == 0 {
    $out.stdout
    | lines
    | where $it =~ '^ {2}[A-Za-z]'
    | parse --regex '^ {2}(?P<value>[^\s*]+)\*?\s+(?P<description>.+)$'
    | where { |it| $it.value not-in $known }
  } else {
    []
  }
}

# ==============================================================================
# Standalone docker-compose externs
# ==============================================================================

# Define and run multi-container applications with Docker
export extern "docker-compose" [
  command?: string@"nu-complete docker-compose subcommands-fallback" # Subcommands
  --all-resources                                      # Include all resources, even those not used by services
  --ansi: string                                       # Control ANSI control characters ("never"|"always"|"auto")
  --compatibility                                      # Run compose in backward compatibility mode
  --dry-run                                            # Execute command in dry run mode
  --env-file: path                                     # Specify an alternate environment file
  --file(-f): path                                     # Compose configuration files
  --parallel: int                                      # Control max parallelism, -1 for unlimited
  --profile: string                                    # Specify a profile to enable
  --progress: string                                   # Set type of progress output (auto, tty, plain, json, quiet)
  --project-directory: path                            # Specify an alternate working directory
  --project-name(-p): string                           # Project name
  --version(-v)                                        # Show the Docker Compose version information
]

# Create and start containers
export extern "docker-compose up" [
  ...services: string@"nu-complete docker-compose services" # Target services to create and start
  --abort-on-container-exit                            # Stops all containers if any container was stopped
  --abort-on-container-failure                         # Stops all containers if any container had non-zero exit code
  --always-recreate-deps                               # Recreate dependent containers
  --attach: string@"nu-complete docker-compose services" # Restrict attaching to specified services
  --attach-dependencies                                # Automatically attach to log output of all dependent services
  --build                                              # Build images before starting containers
  --detach(-d)                                         # Detached mode: Run containers in the background
  --dry-run                                            # Execute command in dry run mode
  --exit-code-from: string@"nu-complete docker-compose services" # Return exit code of selected service container
  --force-recreate                                     # Recreate containers even if configuration and image haven't changed
  --menu                                               # Enable interactive shortcuts when running attached
  --no-attach: string@"nu-complete docker-compose services" # Do not attach to specified services
  --no-build                                           # Don't build an image, even if policy
  --no-color                                           # Produce monochrome output
  --no-deps                                            # Don't start linked services
  --no-log-prefix                                      # Don't print prefix in logs
  --no-recreate                                        # If containers already exist, don't recreate them
  --no-start                                           # Don't start services after creating them
  --pull: string@"nu-complete docker-compose pull policies" # Pull image before running ("always", "missing", "never")
  --quiet-build                                        # Suppress build output
  --quiet-pull                                         # Pull without printing progress information
  --remove-orphans                                     # Remove containers for services not defined in Compose file
  --renew-anon-volumes(-V)                             # Recreate anonymous volumes instead of retrieving data from previous containers
  --scale: string                                      # Scale SERVICE to NUM instances (SERVICE=NUM)
  --timeout(-t): int                                   # Use this timeout in seconds for container shutdown
  --timestamps                                         # Show timestamps
  --wait                                               # Wait for services to be running|healthy
  --wait-timeout: int                                  # Maximum duration in seconds to wait for project to be running|healthy
  --watch(-w)                                          # Watch source code and rebuild/refresh containers when files update
  --yes(-y)                                            # Assume "yes" as answer to all prompts
]

# Stop and remove containers, networks
export extern "docker-compose down" [
  ...services: string@"nu-complete docker-compose services" # Services to remove
  --dry-run                                            # Execute command in dry run mode
  --remove-orphans                                     # Remove containers for services not defined in Compose file
  --rmi: string                                        # Remove images used by services ("local"|"all")
  --timeout(-t): int                                   # Specify a shutdown timeout in seconds
  --volumes(-v)                                        # Remove named volumes declared in "volumes" section and anonymous volumes
]

# List containers
export extern "docker-compose ps" [
  ...services: string@"nu-complete docker-compose services" # Filter by service
  --all(-a)                                            # Show all stopped containers
  --dry-run                                            # Execute command in dry run mode
  --filter: string                                     # Filter services by property (supported: status)
  --format: string                                     # Format output using custom template (table|json)
  --no-trunc                                           # Don't truncate output
  --orphans                                            # Include orphaned services (default true)
  --quiet(-q)                                          # Only display IDs
  --services                                           # Display services
  --status: string@"nu-complete docker-compose service status" # Filter services by status
]

# View output from containers
export extern "docker-compose logs" [
  ...services: string@"nu-complete docker-compose services" # Target services to view logs
  --dry-run                                            # Execute command in dry run mode
  --follow(-f)                                         # Follow log output
  --index: int                                         # Index of container if service has multiple replicas
  --no-color                                           # Produce monochrome output
  --no-log-prefix                                      # Don't print prefix in logs
  --since: string                                      # Show logs since timestamp or relative (e.g. 42m)
  --tail(-n): string                                   # Number of lines to show from end of logs
  --timestamps(-t)                                     # Show timestamps
  --until: string                                      # Show logs before timestamp or relative
]

# Build or rebuild services
export extern "docker-compose build" [
  ...services: string@"nu-complete docker-compose services" # Services to build
  --build-arg: string                                  # Set build-time variables for services
  --builder: string                                    # Set builder to use
  --check                                              # Check build configuration
  --dry-run                                            # Execute command in dry run mode
  --memory(-m): string                                 # Set memory limit for build container
  --no-cache                                           # Do not use cache when building image
  --print                                              # Print equivalent bake file
  --pull                                               # Always attempt to pull a newer version of image
  --push                                               # Push service images
  --quiet(-q)                                          # Suppress build output
  --ssh: string                                        # Set SSH authentications used when building
  --with-dependencies                                  # Also build dependencies (transitively)
]

# Restart service containers
export extern "docker-compose restart" [
  ...services: string@"nu-complete docker-compose services" # Target services
  --dry-run                                            # Execute command in dry run mode
  --no-deps                                            # Don't restart dependent services
  --timeout(-t): int                                   # Specify a shutdown timeout in seconds
]

# Start services
export extern "docker-compose start" [
  ...services: string@"nu-complete docker-compose services" # Target services
  --dry-run                                            # Execute command in dry run mode
  --wait                                               # Wait for services to be running|healthy
  --wait-timeout: int                                  # Maximum duration in seconds to wait
]

# Stop services
export extern "docker-compose stop" [
  ...services: string@"nu-complete docker-compose services" # Target services
  --dry-run                                            # Execute command in dry run mode
  --timeout(-t): int                                   # Specify a shutdown timeout in seconds
]

# Execute a command in a running container
export extern "docker-compose exec" [
  service: string@"nu-complete docker-compose services" # Target service
  command?: string                                     # Command to execute
  ...args: string                                      # Command arguments
  --detach(-d)                                         # Detached mode: Run command in background
  --dry-run                                            # Execute command in dry run mode
  --env(-e): string                                    # Set environment variables
  --index: int                                         # Index of container if service has multiple replicas
  --no-tty(-T)                                         # Disable pseudo-TTY allocation
  --privileged                                         # Give extended privileges to process
  --user(-u): string                                   # Run command as this user
  --workdir(-w): string                                # Path to workdir directory for this command
]

# Run a one-off command on a service
export extern "docker-compose run" [
  service: string@"nu-complete docker-compose services" # Target service
  command?: string                                     # Command to run
  ...args: string                                      # Command arguments
  --build                                              # Build image before starting container
  --cap-add: string                                    # Add Linux capabilities
  --cap-drop: string                                   # Drop Linux capabilities
  --detach(-d)                                         # Run container in background and print container ID
  --dry-run                                            # Execute command in dry run mode
  --entrypoint: string                                 # Override entrypoint of image
  --env(-e): string                                    # Set environment variables
  --interactive(-i)                                    # Keep STDIN open even if not attached
  --label(-l): string                                  # Add or override a label
  --name: string                                       # Assign a name to container
  --no-deps                                            # Don't start linked services
  --no-tty(-T)                                         # Disable pseudo-TTY allocation
  --publish(-p): string                                # Publish container's port(s) to host
  --pull: string@"nu-complete docker-compose pull policies" # Pull image before running
  --quiet(-q)                                          # Don't print anything to STDOUT
  --remove-orphans                                     # Remove containers for services not defined in Compose file
  --rm                                                 # Automatically remove container when it exits
  --service-ports(-P)                                  # Run command with all service's ports enabled
  --user(-u): string                                   # Run as specified username or uid
  --volume(-v): string                                 # Bind mount a volume
  --workdir(-w): string                                # Working directory inside container
]

# Removes stopped service containers
export extern "docker-compose rm" [
  ...services: string@"nu-complete docker-compose services" # Services to remove
  --dry-run                                            # Execute command in dry run mode
  --force(-f)                                          # Don't ask to confirm removal
  --stop(-s)                                           # Stop containers, if required, before removing
  --volumes(-v)                                        # Remove any anonymous volumes attached to containers
]

# Pull service images
export extern "docker-compose pull" [
  ...services: string@"nu-complete docker-compose services" # Services to pull
  --dry-run                                            # Execute command in dry run mode
  --ignore-buildable                                   # Ignore images that can be built
  --ignore-pull-failures                               # Pull what it can and ignores images with pull failures
  --include-deps                                       # Also pull services declared as dependencies
  --policy: string                                     # Apply pull policy ("missing"|"always")
  --quiet(-q)                                          # Pull without printing progress information
]

# Push service images
export extern "docker-compose push" [
  ...services: string@"nu-complete docker-compose services" # Services to push
  --dry-run                                            # Execute command in dry run mode
  --ignore-push-failures                               # Push what it can and ignores images with push failures
  --include-deps                                       # Also push images of services declared as dependencies
  --quiet(-q)                                          # Push without printing progress information
]

# Parse, resolve and render compose file in canonical format
export extern "docker-compose config" [
  ...services: string@"nu-complete docker-compose services" # Services to check
  --dry-run                                            # Execute command in dry run mode
  --environment                                        # Print environment used for interpolation
  --format: string                                     # Format output (yaml|json)
  --hash: string                                       # Print service config hash, one per line
  --images                                             # Print image names, one per line
  --models                                             # Print model names, one per line
  --networks                                           # Print network names, one per line
  --no-consistency                                     # Don't check model consistency
  --no-interpolate                                     # Don't interpolate environment variables
  --output(-o): path                                   # Save to file (default: stdout)
  --profiles                                           # Print profile names, one per line
  --quiet(-q)                                          # Only validate configuration, don't print
  --resolve-image-digests                              # Pin image tags to digests
  --services                                           # Print service names, one per line
  --volumes                                            # Print volume names, one per line
]

# Creates containers for a service
export extern "docker-compose create" [
  ...services: string@"nu-complete docker-compose services"
  --build                                              # Build images before creating containers
  --dry-run                                            # Execute command in dry run mode
  --force-recreate                                     # Recreate containers even if configuration and image haven't changed
  --no-build                                           # Don't build an image, even if policy
  --no-recreate                                        # If containers already exist, don't recreate them
  --pull: string@"nu-complete docker-compose pull policies" # Pull image before creating
  --remove-orphans                                     # Remove containers for services not defined in Compose file
]

# Receive real time events from containers
export extern "docker-compose events" [
  ...services: string@"nu-complete docker-compose services"
  --dry-run                                            # Execute command in dry run mode
  --json                                               # Output events as a stream of json objects
  --since: string                                      # Show all events created since timestamp
  --until: string                                      # Stream events until this timestamp
]

# List images used by created containers
export extern "docker-compose images" [
  ...services: string@"nu-complete docker-compose services"
  --dry-run                                            # Execute command in dry run mode
  --format: string                                     # Format output (table|json)
  --quiet(-q)                                          # Only display IDs
]

# Force stop service containers
export extern "docker-compose kill" [
  ...services: string@"nu-complete docker-compose services"
  --dry-run                                            # Execute command in dry run mode
  --remove-orphans                                     # Remove containers for services not defined in Compose file
  --signal(-s): string                                 # SIGNAL to send to container (default: SIGKILL)
]

# Pause services
export extern "docker-compose pause" [
  ...services: string@"nu-complete docker-compose services"
  --dry-run                                            # Execute command in dry run mode
]

# Unpause services
export extern "docker-compose unpause" [
  ...services: string@"nu-complete docker-compose services"
  --dry-run                                            # Execute command in dry run mode
]

# Print the public port for a port binding
export extern "docker-compose port" [
  service: string@"nu-complete docker-compose services"
  port: string                                         # Private port
  --dry-run                                            # Execute command in dry run mode
  --index: int                                         # Index of container if service has multiple replicas
  --protocol: string                                   # tcp or udp (default: tcp)
]

# Display a live stream of container(s) resource usage statistics
export extern "docker-compose stats" [
  ...services: string@"nu-complete docker-compose services"
  --all(-a)                                            # Show all containers (default shows just running)
  --dry-run                                            # Execute command in dry run mode
  --format: string                                     # Format output using custom template
  --no-stream                                          # Disable streaming stats and only pull first result
  --no-trunc                                           # Do not truncate output
]

# Display the running processes
export extern "docker-compose top" [
  ...services: string@"nu-complete docker-compose services"
  --dry-run                                            # Execute command in dry run mode
]

# Show the Docker Compose version information
export extern "docker-compose version" [
  --dry-run                                            # Execute command in dry run mode
  --format(-f): string                                 # Format output (pretty|json)
  --short                                              # Shows only Compose's version number
]

# Block until containers of all (or specified) services stop
export extern "docker-compose wait" [
  service: string@"nu-complete docker-compose services"
  ...services: string@"nu-complete docker-compose services"
  --down-project                                       # Drops project when first container stops
  --dry-run                                            # Execute command in dry run mode
]

# Watch build context for service and rebuild/refresh containers when files update
export extern "docker-compose watch" [
  ...services: string@"nu-complete docker-compose services"
  --dry-run                                            # Execute command in dry run mode
  --no-up                                              # Do not build & start services before watching
  --prune                                              # Prune dangling images on rebuild
  --quiet                                              # Hide build output
]

# Scale services
export extern "docker-compose scale" [
  ...service_scales: string                            # SERVICE=NUM
  --dry-run                                            # Execute command in dry run mode
  --no-deps                                            # Don't start dependent services
]

# Attach local standard input, output, and error streams to a service's running container
export extern "docker-compose attach" [
  service: string@"nu-complete docker-compose services"
  --dry-run                                            # Execute command in dry run mode
  --index: int                                         # Index of container if service has multiple replicas
  --no-stdin                                           # Do not attach STDIN
  --sig-proxy                                          # Proxy all received signals to process
]

# Copy files/folders between a service container and local filesystem
export extern "docker-compose cp" [
  source: string                                       # SERVICE:SRC_PATH or SRC_PATH
  target: string                                       # SERVICE:DEST_PATH or DEST_PATH
  --all                                                # Include containers created by run command
  --archive(-a)                                        # Archive mode (copy all uid/gid information)
  --dry-run                                            # Execute command in dry run mode
  --follow-link(-L)                                    # Always follow symbol link in SRC_PATH
  --index: int                                         # Index of container if service has multiple replicas
]
