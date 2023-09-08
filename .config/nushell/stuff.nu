export def with-dot-env [filename: string, command: closure] {
    with-env (open -r $filename | lines | parse "{env_key}={env_value}" | transpose -r) $command
}

export def poetry-run [...args: string] {
    with-dot-env .env { poetry run $args }
}

export def poetry-run-python [filename: string] {
    with-dot-env .env { poetry run python $filename }
}
