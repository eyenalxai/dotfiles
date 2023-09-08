export def with-dot-env [filename: string, command: closure] {
    with-env (open -r $filename | lines | parse "{env_key}={env_value}" | transpose -r) $command
}

export def poetry-run [command: closure] {
    with-dot-env .env $command
}

