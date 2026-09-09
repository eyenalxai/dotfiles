# docker-completions.nu - Native completions for Docker and Docker Compose
# Supports subcommands, flags, container/image/volume/network completion, and compose services

def "nu-complete docker containers all" [] {
  let out = (do { ^docker ps -a --format "{{.Names}}\t{{.ID}} ({{.Image}} - {{.Status}})" } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines | where $it != "" | parse "{value}\t{description}"
  } else {
    []
  }
}

def "nu-complete docker containers running" [] {
  let out = (do { ^docker ps --format "{{.Names}}\t{{.ID}} ({{.Image}})" } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines | where $it != "" | parse "{value}\t{description}"
  } else {
    []
  }
}

def "nu-complete docker images" [] {
  let out = (do { ^docker images --format "{{.Repository}}:{{.Tag}}\t{{.ID}} ({{.Size}})" } | complete)
  if $out.exit_code == 0 {
    $out.stdout
    | lines
    | where $it != ""
    | where { |it| not ($it starts-with "<none>") }
    | parse "{value}\t{description}"
  } else {
    []
  }
}

def "nu-complete docker volumes" [] {
  let out = (do { ^docker volume ls --format "{{.Name}}\t{{.Driver}}" } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines | where $it != "" | parse "{value}\t{description}"
  } else {
    []
  }
}

def "nu-complete docker networks" [] {
  let out = (do { ^docker network ls --format "{{.Name}}\t{{.Driver}} ({{.Scope}})" } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines | where $it != "" | parse "{value}\t{description}"
  } else {
    []
  }
}

def "nu-complete docker contexts" [] {
  let out = (do { ^docker context ls --format "{{.Name}}\t{{.Description}}" } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines | where $it != "" | parse "{value}\t{description}"
  } else {
    []
  }
}

def "nu-complete docker compose services" [] {
  let out = (do { ^docker compose config --services } | complete)
  if $out.exit_code == 0 {
    $out.stdout | lines | where $it != ""
  } else {
    []
  }
}

def "nu-complete docker compose service status" [] {
  [paused, restarting, removing, running, dead, created, exited]
}

def "nu-complete docker pull policies" [] {
  [always, missing, never]
}

def "nu-complete docker restart policies" [] {
  ["no", "on-failure", "always", "unless-stopped"]
}

def "nu-complete docker log levels" [] {
  ["debug", "info", "warn", "error", "fatal"]
}

def "nu-complete docker compose subcommands" [] {
  [
    { value: "attach", description: "Attach local standard input, output, and error streams to a service's running container" },
    { value: "bridge", description: "Convert compose files into another model" },
    { value: "build", description: "Build or rebuild services" },
    { value: "commit", description: "Create a new image from a service container's changes" },
    { value: "config", description: "Parse, resolve and render compose file in canonical format" },
    { value: "cp", description: "Copy files/folders between a service container and the local filesystem" },
    { value: "create", description: "Creates containers for a service" },
    { value: "down", description: "Stop and remove containers, networks" },
    { value: "events", description: "Receive real time events from containers" },
    { value: "exec", description: "Execute a command in a running container" },
    { value: "export", description: "Export a service container's filesystem as a tar archive" },
    { value: "images", description: "List images used by the created containers" },
    { value: "kill", description: "Force stop service containers" },
    { value: "logs", description: "View output from containers" },
    { value: "ls", description: "List running compose projects" },
    { value: "pause", description: "Pause services" },
    { value: "port", description: "Print the public port for a port binding" },
    { value: "ps", description: "List containers" },
    { value: "publish", description: "Publish compose application" },
    { value: "pull", description: "Pull service images" },
    { value: "push", description: "Push service images" },
    { value: "restart", description: "Restart service containers" },
    { value: "rm", description: "Removes stopped service containers" },
    { value: "run", description: "Run a one-off command on a service" },
    { value: "scale", description: "Scale services" },
    { value: "start", description: "Start services" },
    { value: "stats", description: "Display a live stream of container(s) resource usage statistics" },
    { value: "stop", description: "Stop services" },
    { value: "top", description: "Display the running processes" },
    { value: "unpause", description: "Unpause services" },
    { value: "up", description: "Create and start containers" },
    { value: "version", description: "Show the Docker Compose version information" },
    { value: "volumes", description: "List volumes" },
    { value: "wait", description: "Block until containers of all (or specified) services stop" },
    { value: "watch", description: "Watch build context for service and rebuild/refresh containers when files are updated" }
  ]
}

def "nu-complete docker extern-subcommands" [] {
  [
    "attach", "bake", "build", "builder", "buildx", "checkpoint", "commit", "compose",
    "config", "container", "context", "cp", "create", "diff", "events", "exec", "export",
    "history", "image", "images", "import", "info", "inspect", "kill", "load", "login",
    "logout", "logs", "manifest", "network", "node", "pause", "plugin", "port", "ps",
    "pull", "push", "rename", "restart", "rm", "rmi", "run", "save", "search", "secret",
    "service", "stack", "start", "stats", "stop", "swarm", "system", "tag", "top",
    "unpause", "update", "version", "volume", "wait"
  ]
}

def "nu-complete docker subcommands-fallback" [] {
  let known = (nu-complete docker extern-subcommands)
  let out = (do { ^docker --help } | complete)
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
# Main Docker Command
# ==============================================================================

# A self-sufficient runtime for containers
export extern "docker" [
  command?: string@"nu-complete docker subcommands-fallback" # Subcommands
  --config: path                       # Location of client config files (default "~/.docker")
  --context(-c): string@"nu-complete docker contexts" # Name of the context to use to connect to daemon
  --debug(-D)                          # Enable debug mode
  --host(-H): string                   # Daemon socket(s) to connect to
  --log-level(-l): string@"nu-complete docker log levels" # Set the logging level ("debug"|"info"|"warn"|"error"|"fatal")
  --tls                                # Use TLS; implied by --tlsverify
  --tlscacert: path                    # Trust certs signed only by this CA
  --tlscert: path                      # Path to TLS certificate file
  --tlskey: path                       # Path to TLS key file
  --tlsverify                          # Use TLS and verify the remote
  --version(-v)                        # Print version information and quit
  --help(-h)                           # Print help
]

# ==============================================================================
# Common Standalone Docker Commands
# ==============================================================================

# Create and run a new container from an image
export extern "docker run" [
  image: string@"nu-complete docker images"             # Container image to run
  command?: string                                     # Command to run inside container
  ...args: string                                      # Arguments to command
  --add-host: string                                   # Add a custom host-to-IP mapping (host:ip)
  --attach(-a): string                                 # Attach to STDIN, STDOUT or STDERR
  --cap-add: string                                    # Add Linux capabilities
  --cap-drop: string                                   # Drop Linux capabilities
  --cgroup-parent: string                              # Optional parent cgroup for container
  --cgroupns: string                                   # Cgroup namespace to use (host|private)
  --cidfile: path                                      # Write container ID to file
  --cpus: string                                       # Number of CPUs
  --cpuset-cpus: string                                # CPUs in which to allow execution (0-3, 0,1)
  --detach(-d)                                         # Run container in background and print container ID
  --device: string                                     # Add a host device to container
  --dns: string                                        # Set custom DNS servers
  --dns-search: string                                 # Set custom DNS search domains
  --entrypoint: string                                 # Overwrite default ENTRYPOINT
  --env(-e): string                                    # Set environment variables
  --env-file: path                                     # Read in a file of environment variables
  --expose: string                                     # Expose a port or range of ports
  --gpus: string                                       # GPU devices to add to container ('all' to pass all)
  --health-cmd: string                                 # Command to run to check health
  --help(-h)                                           # Print usage
  --hostname(-h): string                               # Container host name
  --init                                               # Run an init inside container
  --interactive(-i)                                    # Keep STDIN open even if not attached
  --ip: string                                         # IPv4 address (e.g., 172.30.100.104)
  --ipc: string                                        # IPC mode to use
  --label(-l): string                                  # Set metadata on container
  --label-file: path                                   # Read in a line-delimited file of labels
  --link: string                                       # Add link to another container
  --log-driver: string                                 # Logging driver for container
  --memory(-m): string                                 # Memory limit
  --memory-swap: string                                # Swap limit equal to memory plus swap
  --mount: string                                      # Attach a filesystem mount to container
  --name: string                                       # Assign a name to container
  --network: string@"nu-complete docker networks"      # Connect a container to a network
  --network-alias: string                              # Add network-scoped alias for container
  --no-healthcheck                                     # Disable any container-specified HEALTHCHECK
  --platform: string                                   # Set platform if server is multi-platform capable
  --privileged                                         # Give extended privileges to this container
  --publish(-p): string                                # Publish a container's port(s) to the host
  --publish-all(-P)                                    # Publish all exposed ports to random ports
  --pull: string@"nu-complete docker pull policies"    # Pull image before running ("always", "missing", "never")
  --quiet(-q)                                          # Suppress pull output
  --read-only                                          # Mount container's root filesystem as read only
  --restart: string@"nu-complete docker restart policies" # Restart policy to apply when a container exits
  --rm                                                 # Automatically remove container when it exits
  --runtime: string                                    # Runtime to use for container
  --shm-size: string                                   # Size of /dev/shm
  --sig-proxy                                          # Proxy received signals to process
  --stop-signal: string                                # Signal to stop container
  --stop-timeout: int                                  # Timeout (in seconds) to stop container
  --tmpfs: string                                      # Mount a tmpfs directory
  --tty(-t)                                            # Allocate a pseudo-TTY
  --user(-u): string                                   # Username or UID (format: <name|uid>[:<group|gid>])
  --volume(-v): string                                 # Bind mount a volume
  --volumes-from: string@"nu-complete docker containers all" # Mount volumes from specified container(s)
  --workdir(-w): string                                # Working directory inside container
]

# Execute a command in a running container
export extern "docker exec" [
  container: string@"nu-complete docker containers running" # Container to execute in
  command?: string                                          # Command to execute
  ...args: string                                           # Command arguments
  --detach(-d)                                              # Detached mode: run command in background
  --detach-keys: string                                     # Override key sequence for detaching
  --env(-e): string                                         # Set environment variables
  --env-file: path                                          # Read in a file of environment variables
  --interactive(-i)                                         # Keep STDIN open even if not attached
  --privileged                                              # Give extended privileges to command
  --tty(-t)                                                 # Allocate a pseudo-TTY
  --user(-u): string                                        # Username or UID (format: <name|uid>[:<group|gid>])
  --workdir(-w): string                                     # Working directory inside container
]

# List containers
export extern "docker ps" [
  --all(-a)                                            # Show all containers (default shows just running)
  --filter(-f): string                                 # Filter output based on conditions provided
  --format: string                                     # Format output using a custom template
  --last(-n): int                                      # Show n last created containers (includes all states)
  --latest(-l)                                         # Show the latest created container
  --no-trunc                                           # Don't truncate output
  --quiet(-q)                                          # Only display container IDs
  --size(-s)                                           # Display total file sizes
]

# Build an image from a Dockerfile
export extern "docker build" [
  path?: path                                          # Path or URL to build context
  --add-host: string                                   # Add a custom host-to-IP mapping
  --build-arg: string                                  # Set build-time variables
  --cache-from: string                                 # External cache sources
  --check                                              # Check build configuration
  --file(-f): path                                     # Name of the Dockerfile (default: 'PATH/Dockerfile')
  --iidfile: path                                      # Write image ID to a file
  --label: string                                      # Set metadata for an image
  --load                                               # Load image into docker daemon
  --network: string@"nu-complete docker networks"      # Networking mode for RUN instructions during build
  --no-cache                                           # Do not use cache when building image
  --output(-o): string                                 # Output destination
  --platform: string                                   # Set target platform for build
  --progress: string                                   # Set type of progress output (auto, plain, tty)
  --pull                                               # Always attempt to pull a newer version of image
  --push                                               # Push image to registry
  --quiet(-q)                                          # Suppress build output and print image ID on success
  --secret: string                                     # Secret to expose to build
  --ssh: string                                        # SSH agent socket or keys to expose
  --tag(-t): string                                    # Name and optionally a tag in 'name:tag' format
  --target: string                                     # Set target build stage to build
]

# Download an image from a registry
export extern "docker pull" [
  image: string                                        # Image name to pull
  --all-tags(-a)                                       # Download all tagged images in repository
  --disable-content-trust                              # Skip image verification
  --platform: string                                   # Set platform if server is multi-platform capable
  --quiet(-q)                                          # Suppress verbose output
]

# Upload an image to a registry
export extern "docker push" [
  image: string@"nu-complete docker images"            # Image name to push
  --all-tags(-a)                                       # Push all tags in repository
  --disable-content-trust                              # Skip image signing
  --quiet(-q)                                          # Suppress verbose output
]

# List images
export extern "docker images" [
  repository?: string@"nu-complete docker images"      # Filter by repository
  --all(-a)                                            # Show all images (default hides intermediate images)
  --digests                                            # Show digests
  --filter(-f): string                                 # Filter output based on conditions provided
  --format: string                                     # Format output using a custom template
  --no-trunc                                           # Don't truncate output
  --quiet(-q)                                          # Only show image IDs
  --tree                                               # List multi-platform images as a tree
]

# Log in to a Docker registry
export extern "docker login" [
  server?: string                                      # Docker registry URL
  --password(-p): string                               # Password
  --password-stdin                                     # Take password from stdin
  --username(-u): string                               # Username
]

# Log out from a Docker registry
export extern "docker logout" [
  server?: string                                      # Docker registry URL
]

# Search Docker Hub for images
export extern "docker search" [
  term: string                                         # Search term
  --filter(-f): string                                 # Filter output based on conditions provided
  --format: string                                     # Pretty-print search using a template
  --limit: int                                         # Max number of search results
  --no-trunc                                           # Don't truncate output
]

# Show the Docker version information
export extern "docker version" [
  --format(-f): string                                 # Format output using given template
  --kubeconfig: path                                   # Kubernetes config file
]

# Display system-wide information
export extern "docker info" [
  --format(-f): string                                 # Format output using given template
]

# Attach local standard input, output, and error streams to a running container
export extern "docker attach" [
  container: string@"nu-complete docker containers running" # Container to attach to
  --detach-keys: string                                     # Override key sequence for detaching
  --no-stdin                                                # Do not attach STDIN
  --sig-proxy                                               # Proxy all received signals to process
]

# Create a new image from a container's changes
export extern "docker commit" [
  container: string@"nu-complete docker containers all" # Source container
  repository?: string                                   # Repository name for new image
  --author(-a): string                                  # Author (e.g., "Name <email@example.com>")
  --change(-c): string                                  # Apply Dockerfile instruction to created image
  --message(-m): string                                 # Commit message
  --pause(-p)                                           # Pause container during commit
]

# Copy files/folders between a container and local filesystem
export extern "docker cp" [
  source: string                                       # Source path (CONTAINER:SRC_PATH or SRC_PATH)
  target: string                                       # Target path (CONTAINER:DEST_PATH or DEST_PATH)
  --archive(-a)                                        # Archive mode (copy all uid/gid information)
  --follow-link(-L)                                    # Always follow symbol link in source
  --quiet(-q)                                          # Suppress progress output during copy
]

# Create a new container
export extern "docker create" [
  image: string@"nu-complete docker images"             # Container image
  command?: string                                     # Command to run inside container
  ...args: string                                      # Command arguments
  --entrypoint: string                                 # Overwrite default ENTRYPOINT
  --env(-e): string                                    # Set environment variables
  --env-file: path                                     # Read in a file of environment variables
  --hostname(-h): string                               # Container host name
  --interactive(-i)                                    # Keep STDIN open even if not attached
  --name: string                                       # Assign a name to container
  --network: string@"nu-complete docker networks"      # Connect a container to a network
  --publish(-p): string                                # Publish container port(s) to host
  --tty(-t)                                            # Allocate a pseudo-TTY
  --user(-u): string                                   # Username or UID
  --volume(-v): string                                 # Bind mount a volume
  --workdir(-w): string                                # Working directory inside container
]

# Inspect changes to files or directories on a container's filesystem
export extern "docker diff" [
  container: string@"nu-complete docker containers all"
]

# Get real time events from the server
export extern "docker events" [
  --filter(-f): string                                 # Filter output based on conditions provided
  --format: string                                     # Format the output using template
  --since: string                                      # Show all events created since timestamp
  --until: string                                      # Stream events until this timestamp
]

# Export a container's filesystem as a tar archive
export extern "docker export" [
  container: string@"nu-complete docker containers all"
  --output(-o): path                                   # Write to a file instead of STDOUT
]

# Show the history of an image
export extern "docker history" [
  image: string@"nu-complete docker images"
  --format: string                                     # Pretty-print images using template
  --no-trunc                                           # Don't truncate output
  --quiet(-q)                                          # Only show numeric IDs
]

# Import the contents from a tarball to create a filesystem image
export extern "docker import" [
  file: path                                           # Tar file to import
  repository?: string                                  # Repository and tag
  --change(-c): string                                 # Apply Dockerfile instruction
  --message(-m): string                                # Commit message
  --platform: string                                   # Set platform
]

# Return low-level information on Docker objects
export extern "docker inspect" [
  ...names: string                                     # Names or IDs of containers, images, volumes, etc.
  --format(-f): string                                 # Format output using given Go template
  --size(-s)                                           # Display total file sizes if type is container
  --type: string                                       # Return JSON for specified type
]

# Kill one or more running containers
export extern "docker kill" [
  ...containers: string@"nu-complete docker containers running"
  --signal(-s): string                                 # Signal to send to container (default: KILL)
]

# Load an image from a tar archive or STDIN
export extern "docker load" [
  --input(-i): path                                    # Read from archive file, instead of STDIN
  --quiet(-q)                                          # Suppress load output
]

# Fetch the logs of a container
export extern "docker logs" [
  container: string@"nu-complete docker containers all"
  --details                                            # Show extra details provided to logs
  --follow(-f)                                         # Follow log output
  --no-log-prefix                                      # Don't print prefix in logs
  --since: string                                      # Show logs since timestamp or relative (e.g. 42m)
  --tail(-n): string                                   # Number of lines to show from end of logs
  --timestamps(-t)                                     # Show timestamps
  --until: string                                      # Show logs before timestamp or relative
]

# Pause all processes within one or more containers
export extern "docker pause" [
  ...containers: string@"nu-complete docker containers running"
]

# List port mappings or a specific mapping for the container
export extern "docker port" [
  container: string@"nu-complete docker containers running"
  port?: string                                        # Private port
]

# Rename a container
export extern "docker rename" [
  container: string@"nu-complete docker containers all"
  name: string                                         # New container name
]

# Restart one or more containers
export extern "docker restart" [
  ...containers: string@"nu-complete docker containers all"
  --signal(-s): string                                 # Signal to stop container
  --time(-t): int                                      # Seconds to wait before killing container
]

# Remove one or more containers
export extern "docker rm" [
  ...containers: string@"nu-complete docker containers all"
  --force(-f)                                          # Force removal of running container
  --link(-l)                                           # Remove specified link
  --volumes(-v)                                        # Remove anonymous volumes associated with container
]

# Remove one or more images
export extern "docker rmi" [
  ...images: string@"nu-complete docker images"
  --force(-f)                                          # Force removal of image
  --no-prune                                           # Do not delete untagged parents
]

# Save one or more images to a tar archive
export extern "docker save" [
  ...images: string@"nu-complete docker images"
  --output(-o): path                                   # Write to a file instead of STDOUT
]

# Start one or more stopped containers
export extern "docker start" [
  ...containers: string@"nu-complete docker containers all"
  --attach(-a)                                         # Attach STDOUT/STDERR and forward signals
  --checkpoint: string                                 # Restore from this checkpoint
  --checkpoint-dir: path                               # Use custom checkpoint storage directory
  --detach-keys: string                                # Override key sequence for detaching
  --interactive(-i)                                    # Attach container's STDIN
]

# Display a live stream of container(s) resource usage statistics
export extern "docker stats" [
  ...containers: string@"nu-complete docker containers running"
  --all(-a)                                            # Show all containers (default shows just running)
  --format: string                                     # Format output using custom template
  --no-stream                                          # Disable streaming stats and only pull first result
  --no-trunc                                           # Do not truncate output
]

# Stop one or more running containers
export extern "docker stop" [
  ...containers: string@"nu-complete docker containers running"
  --signal(-s): string                                 # Signal to send to container
  --time(-t): int                                      # Seconds to wait before killing container
]

# Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
export extern "docker tag" [
  source: string@"nu-complete docker images"
  target: string
]

# Display the running processes of a container
export extern "docker top" [
  container: string@"nu-complete docker containers running"
  ...args: string
]

# Unpause all processes within one or more containers
export extern "docker unpause" [
  ...containers: string@"nu-complete docker containers all"
]

# Update configuration of one or more containers
export extern "docker update" [
  ...containers: string@"nu-complete docker containers all"
  --cpus: string                                       # Number of CPUs
  --memory(-m): string                                 # Memory limit
  --memory-swap: string                                # Swap limit equal to memory plus swap
  --pids-limit: int                                    # Tune container pids limit
  --restart: string@"nu-complete docker restart policies" # Restart policy to apply when container exits
]

# Block until one or more containers stop, then print their exit codes
export extern "docker wait" [
  ...containers: string@"nu-complete docker containers running"
]

# ==============================================================================
# Management Commands: container, image, volume, network, context, system, buildx
# ==============================================================================

# Manage containers
export extern "docker container" [
  --help(-h)
]
export extern "docker container ls" [
  --all(-a)
  --filter(-f): string
  --format: string
  --last(-n): int
  --latest(-l)
  --no-trunc
  --quiet(-q)
  --size(-s)
]
export extern "docker container run" [
  image: string@"nu-complete docker images"
  command?: string
  ...args: string
  --detach(-d)
  --interactive(-i)
  --tty(-t)
  --rm
  --name: string
  --publish(-p): string
  --volume(-v): string
  --env(-e): string
  --env-file: path
  --network: string@"nu-complete docker networks"
  --restart: string@"nu-complete docker restart policies"
]
export extern "docker container start" [
  ...containers: string@"nu-complete docker containers all"
  --attach(-a)
  --interactive(-i)
]
export extern "docker container stop" [
  ...containers: string@"nu-complete docker containers running"
  --time(-t): int
]
export extern "docker container restart" [
  ...containers: string@"nu-complete docker containers all"
  --time(-t): int
]
export extern "docker container rm" [
  ...containers: string@"nu-complete docker containers all"
  --force(-f)
  --volumes(-v)
]
export extern "docker container prune" [
  --filter: string
  --force(-f)
]
export extern "docker container logs" [
  container: string@"nu-complete docker containers all"
  --follow(-f)
  --timestamps(-t)
  --tail(-n): string
]
export extern "docker container exec" [
  container: string@"nu-complete docker containers running"
  command?: string
  ...args: string
  --detach(-d)
  --interactive(-i)
  --tty(-t)
]
export extern "docker container inspect" [
  ...containers: string@"nu-complete docker containers all"
  --format(-f): string
  --size(-s)
]
export extern "docker container stats" [
  ...containers: string@"nu-complete docker containers running"
  --all(-a)
  --no-stream
]
export extern "docker container top" [
  container: string@"nu-complete docker containers running"
]
export extern "docker container port" [
  container: string@"nu-complete docker containers running"
]
export extern "docker container pause" [
  ...containers: string@"nu-complete docker containers running"
]
export extern "docker container unpause" [
  ...containers: string@"nu-complete docker containers all"
]
export extern "docker container kill" [
  ...containers: string@"nu-complete docker containers running"
  --signal(-s): string
]
export extern "docker container attach" [
  container: string@"nu-complete docker containers running"
]
export extern "docker container diff" [
  container: string@"nu-complete docker containers all"
]
export extern "docker container export" [
  container: string@"nu-complete docker containers all"
  --output(-o): path
]
export extern "docker container rename" [
  container: string@"nu-complete docker containers all"
  name: string
]
export extern "docker container wait" [
  ...containers: string@"nu-complete docker containers running"
]

# Manage images
export extern "docker image" [
  --help(-h)
]
export extern "docker image ls" [
  repository?: string@"nu-complete docker images"
  --all(-a)
  --digests
  --filter(-f): string
  --format: string
  --no-trunc
  --quiet(-q)
]
export extern "docker image build" [
  path?: path
  --file(-f): path
  --tag(-t): string
  --no-cache
  --pull
  --quiet(-q)
]
export extern "docker image history" [
  image: string@"nu-complete docker images"
  --format: string
  --no-trunc
  --quiet(-q)
]
export extern "docker image import" [
  file: path
  repository?: string
]
export extern "docker image inspect" [
  ...images: string@"nu-complete docker images"
  --format(-f): string
]
export extern "docker image load" [
  --input(-i): path
  --quiet(-q)
]
export extern "docker image prune" [
  --all(-a)
  --filter: string
  --force(-f)
]
export extern "docker image pull" [
  image: string
  --all-tags(-a)
  --quiet(-q)
]
export extern "docker image push" [
  image: string@"nu-complete docker images"
  --all-tags(-a)
  --quiet(-q)
]
export extern "docker image rm" [
  ...images: string@"nu-complete docker images"
  --force(-f)
  --no-prune
]
export extern "docker image save" [
  ...images: string@"nu-complete docker images"
  --output(-o): path
]
export extern "docker image tag" [
  source: string@"nu-complete docker images"
  target: string
]

# Manage volumes
export extern "docker volume" [
  --help(-h)
]
export extern "docker volume create" [
  name?: string
  --driver(-d): string
  --label: string
]
export extern "docker volume inspect" [
  ...volumes: string@"nu-complete docker volumes"
  --format(-f): string
]
export extern "docker volume ls" [
  --filter(-f): string
  --format: string
  --quiet(-q)
]
export extern "docker volume prune" [
  --filter: string
  --force(-f)
]
export extern "docker volume rm" [
  ...volumes: string@"nu-complete docker volumes"
  --force(-f)
]

# Manage networks
export extern "docker network" [
  --help(-h)
]
export extern "docker network connect" [
  network: string@"nu-complete docker networks"
  container: string@"nu-complete docker containers all"
]
export extern "docker network create" [
  network: string
  --driver(-d): string
  --subnet: string
  --gateway: string
  --internal
]
export extern "docker network disconnect" [
  network: string@"nu-complete docker networks"
  container: string@"nu-complete docker containers running"
  --force(-f)
]
export extern "docker network inspect" [
  ...networks: string@"nu-complete docker networks"
  --format(-f): string
]
export extern "docker network ls" [
  --filter(-f): string
  --format: string
  --quiet(-q)
]
export extern "docker network prune" [
  --filter: string
  --force(-f)
]
export extern "docker network rm" [
  ...networks: string@"nu-complete docker networks"
  --force(-f)
]

# Manage contexts
export extern "docker context" [
  --help(-h)
]
export extern "docker context create" [
  context: string
  --description: string
  --docker: string
  --from: string
]
export extern "docker context export" [
  context: string@"nu-complete docker contexts"
  dest?: path
]
export extern "docker context import" [
  context: string
  file: path
]
export extern "docker context inspect" [
  ...contexts: string@"nu-complete docker contexts"
  --format(-f): string
]
export extern "docker context ls" [
  --format: string
  --quiet(-q)
]
export extern "docker context rm" [
  ...contexts: string@"nu-complete docker contexts"
  --force(-f)
]
export extern "docker context show" []
export extern "docker context use" [
  context: string@"nu-complete docker contexts"
]

# Manage Docker system
export extern "docker system" [
  --help(-h)
]
export extern "docker system df" [
  --format: string
  --verbose(-v)
]
export extern "docker system events" [
  --filter(-f): string
  --format: string
  --since: string
  --until: string
]
export extern "docker system info" [
  --format(-f): string
]
export extern "docker system prune" [
  --all(-a)
  --filter: string
  --force(-f)
  --volumes
]

# Extended build capabilities with BuildKit
export extern "docker builder" [
  --help(-h)
]
export extern "docker buildx" [
  --builder: string
]
export extern "docker buildx bake" [
  ...targets: string
  --file(-f): path
  --load
  --no-cache
  --progress: string
  --pull
  --push
]
export extern "docker buildx build" [
  path?: path
  --add-host: string
  --build-arg: string
  --builder: string
  --cache-from: string
  --cache-to: string
  --file(-f): path
  --load
  --network: string@"nu-complete docker networks"
  --no-cache
  --output(-o): string
  --platform: string
  --progress: string
  --pull
  --push
  --quiet(-q)
  --secret: string
  --ssh: string
  --tag(-t): string
  --target: string
]
export extern "docker buildx create" [
  context?: string
  --name: string
  --driver: string
  --use
]
export extern "docker buildx du" []
export extern "docker buildx inspect" [
  name?: string
  --bootstrap
]
export extern "docker buildx ls" []
export extern "docker buildx prune" [
  --all(-a)
  --force(-f)
]
export extern "docker buildx rm" [
  name?: string
  --force(-f)
]
export extern "docker buildx stop" [
  name?: string
]
export extern "docker buildx use" [
  name: string
  --global
]
export extern "docker buildx version" []

# ==============================================================================
# Docker Compose Subcommand
# ==============================================================================

# Define and run multi-container applications with Docker
export extern "docker compose" [
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
]

# Create and start containers
export extern "docker compose up" [
  ...services: string@"nu-complete docker compose services" # Target services to create and start
  --abort-on-container-exit                            # Stops all containers if any container was stopped
  --abort-on-container-failure                         # Stops all containers if any container had non-zero exit code
  --always-recreate-deps                               # Recreate dependent containers
  --attach: string@"nu-complete docker compose services" # Restrict attaching to specified services
  --attach-dependencies                                # Automatically attach to log output of all dependent services
  --build                                              # Build images before starting containers
  --detach(-d)                                         # Detached mode: Run containers in the background
  --dry-run                                            # Execute command in dry run mode
  --exit-code-from: string@"nu-complete docker compose services" # Return exit code of selected service container
  --force-recreate                                     # Recreate containers even if configuration and image haven't changed
  --menu                                               # Enable interactive shortcuts when running attached
  --no-attach: string@"nu-complete docker compose services" # Do not attach to specified services
  --no-build                                           # Don't build an image, even if policy
  --no-color                                           # Produce monochrome output
  --no-deps                                            # Don't start linked services
  --no-log-prefix                                      # Don't print prefix in logs
  --no-recreate                                        # If containers already exist, don't recreate them
  --no-start                                           # Don't start services after creating them
  --pull: string@"nu-complete docker pull policies"    # Pull image before running ("always", "missing", "never")
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
export extern "docker compose down" [
  ...services: string@"nu-complete docker compose services" # Services to remove
  --dry-run                                            # Execute command in dry run mode
  --remove-orphans                                     # Remove containers for services not defined in Compose file
  --rmi: string                                        # Remove images used by services ("local"|"all")
  --timeout(-t): int                                   # Specify a shutdown timeout in seconds
  --volumes(-v)                                        # Remove named volumes declared in "volumes" section and anonymous volumes
]

# List containers
export extern "docker compose ps" [
  ...services: string@"nu-complete docker compose services" # Filter by service
  --all(-a)                                            # Show all stopped containers
  --dry-run                                            # Execute command in dry run mode
  --filter: string                                     # Filter services by property (supported: status)
  --format: string                                     # Format output using custom template (table|json)
  --no-trunc                                           # Don't truncate output
  --orphans                                            # Include orphaned services (default true)
  --quiet(-q)                                          # Only display IDs
  --services                                           # Display services
  --status: string@"nu-complete docker compose service status" # Filter services by status
]

# View output from containers
export extern "docker compose logs" [
  ...services: string@"nu-complete docker compose services" # Target services to view logs
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
export extern "docker compose build" [
  ...services: string@"nu-complete docker compose services" # Services to build
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
export extern "docker compose restart" [
  ...services: string@"nu-complete docker compose services" # Target services
  --dry-run                                            # Execute command in dry run mode
  --no-deps                                            # Don't restart dependent services
  --timeout(-t): int                                   # Specify a shutdown timeout in seconds
]

# Start services
export extern "docker compose start" [
  ...services: string@"nu-complete docker compose services" # Target services
  --dry-run                                            # Execute command in dry run mode
  --wait                                               # Wait for services to be running|healthy
  --wait-timeout: int                                  # Maximum duration in seconds to wait
]

# Stop services
export extern "docker compose stop" [
  ...services: string@"nu-complete docker compose services" # Target services
  --dry-run                                            # Execute command in dry run mode
  --timeout(-t): int                                   # Specify a shutdown timeout in seconds
]

# Execute a command in a running container
export extern "docker compose exec" [
  service: string@"nu-complete docker compose services" # Target service
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
export extern "docker compose run" [
  service: string@"nu-complete docker compose services" # Target service
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
  --pull: string@"nu-complete docker pull policies"    # Pull image before running
  --quiet(-q)                                          # Don't print anything to STDOUT
  --remove-orphans                                     # Remove containers for services not defined in Compose file
  --rm                                                 # Automatically remove container when it exits
  --service-ports(-P)                                  # Run command with all service's ports enabled
  --user(-u): string                                   # Run as specified username or uid
  --volume(-v): string                                 # Bind mount a volume
  --workdir(-w): string                                # Working directory inside container
]

# Removes stopped service containers
export extern "docker compose rm" [
  ...services: string@"nu-complete docker compose services" # Services to remove
  --dry-run                                            # Execute command in dry run mode
  --force(-f)                                          # Don't ask to confirm removal
  --stop(-s)                                           # Stop containers, if required, before removing
  --volumes(-v)                                        # Remove any anonymous volumes attached to containers
]

# Pull service images
export extern "docker compose pull" [
  ...services: string@"nu-complete docker compose services" # Services to pull
  --dry-run                                            # Execute command in dry run mode
  --ignore-buildable                                   # Ignore images that can be built
  --ignore-pull-failures                               # Pull what it can and ignores images with pull failures
  --include-deps                                       # Also pull services declared as dependencies
  --policy: string                                     # Apply pull policy ("missing"|"always")
  --quiet(-q)                                          # Pull without printing progress information
]

# Push service images
export extern "docker compose push" [
  ...services: string@"nu-complete docker compose services" # Services to push
  --dry-run                                            # Execute command in dry run mode
  --ignore-push-failures                               # Push what it can and ignores images with push failures
  --include-deps                                       # Also push images of services declared as dependencies
  --quiet(-q)                                          # Push without printing progress information
]

# Parse, resolve and render compose file in canonical format
export extern "docker compose config" [
  ...services: string@"nu-complete docker compose services" # Services to check
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
export extern "docker compose create" [
  ...services: string@"nu-complete docker compose services"
  --build                                              # Build images before creating containers
  --dry-run                                            # Execute command in dry run mode
  --force-recreate                                     # Recreate containers even if configuration and image haven't changed
  --no-build                                           # Don't build an image, even if policy
  --no-recreate                                        # If containers already exist, don't recreate them
  --pull: string@"nu-complete docker pull policies"    # Pull image before creating
  --remove-orphans                                     # Remove containers for services not defined in Compose file
]

# Receive real time events from containers
export extern "docker compose events" [
  ...services: string@"nu-complete docker compose services"
  --dry-run                                            # Execute command in dry run mode
  --json                                               # Output events as a stream of json objects
  --since: string                                      # Show all events created since timestamp
  --until: string                                      # Stream events until this timestamp
]

# List images used by created containers
export extern "docker compose images" [
  ...services: string@"nu-complete docker compose services"
  --dry-run                                            # Execute command in dry run mode
  --format: string                                     # Format output (table|json)
  --quiet(-q)                                          # Only display IDs
]

# Force stop service containers
export extern "docker compose kill" [
  ...services: string@"nu-complete docker compose services"
  --dry-run                                            # Execute command in dry run mode
  --remove-orphans                                     # Remove containers for services not defined in Compose file
  --signal(-s): string                                 # SIGNAL to send to container (default: SIGKILL)
]

# Pause services
export extern "docker compose pause" [
  ...services: string@"nu-complete docker compose services"
  --dry-run                                            # Execute command in dry run mode
]

# Unpause services
export extern "docker compose unpause" [
  ...services: string@"nu-complete docker compose services"
  --dry-run                                            # Execute command in dry run mode
]

# Print the public port for a port binding
export extern "docker compose port" [
  service: string@"nu-complete docker compose services"
  port: string                                         # Private port
  --dry-run                                            # Execute command in dry run mode
  --index: int                                         # Index of container if service has multiple replicas
  --protocol: string                                   # tcp or udp (default: tcp)
]

# Display a live stream of container(s) resource usage statistics
export extern "docker compose stats" [
  ...services: string@"nu-complete docker compose services"
  --all(-a)                                            # Show all containers (default shows just running)
  --dry-run                                            # Execute command in dry run mode
  --format: string                                     # Format output using custom template
  --no-stream                                          # Disable streaming stats and only pull first result
  --no-trunc                                           # Do not truncate output
]

# Display the running processes
export extern "docker compose top" [
  ...services: string@"nu-complete docker compose services"
  --dry-run                                            # Execute command in dry run mode
]

# Show the Docker Compose version information
export extern "docker compose version" [
  --dry-run                                            # Execute command in dry run mode
  --format(-f): string                                 # Format output (pretty|json)
  --short                                              # Shows only Compose's version number
]

# Block until containers of all (or specified) services stop
export extern "docker compose wait" [
  service: string@"nu-complete docker compose services"
  ...services: string@"nu-complete docker compose services"
  --down-project                                       # Drops project when first container stops
  --dry-run                                            # Execute command in dry run mode
]

# Watch build context for service and rebuild/refresh containers when files update
export extern "docker compose watch" [
  ...services: string@"nu-complete docker compose services"
  --dry-run                                            # Execute command in dry run mode
  --no-up                                              # Do not build & start services before watching
  --prune                                              # Prune dangling images on rebuild
  --quiet                                              # Hide build output
]

# Scale services
export extern "docker compose scale" [
  ...service_scales: string                            # SERVICE=NUM
  --dry-run                                            # Execute command in dry run mode
  --no-deps                                            # Don't start dependent services
]

# Attach local standard input, output, and error streams to a service's running container
export extern "docker compose attach" [
  service: string@"nu-complete docker compose services"
  --dry-run                                            # Execute command in dry run mode
  --index: int                                         # Index of container if service has multiple replicas
  --no-stdin                                           # Do not attach STDIN
  --sig-proxy                                          # Proxy all received signals to process
]

# Copy files/folders between a service container and local filesystem
export extern "docker compose cp" [
  source: string                                       # SERVICE:SRC_PATH or SRC_PATH
  target: string                                       # SERVICE:DEST_PATH or DEST_PATH
  --all                                                # Include containers created by run command
  --archive(-a)                                        # Archive mode (copy all uid/gid information)
  --dry-run                                            # Execute command in dry run mode
  --follow-link(-L)                                    # Always follow symbol link in SRC_PATH
  --index: int                                         # Index of container if service has multiple replicas
]
