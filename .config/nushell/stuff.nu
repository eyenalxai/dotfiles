export def with-dot-env [filename: string, command: closure] {
    with-env (open -r $filename | lines | parse "{env_key}={env_value}" | transpose -r) $command
}

export def poetry-run [...args: string] {
    if ('.env.local' | | path exists) { 
        with-dot-env .env.local { poetry run $args }
    } else {
        poetry run $args
    }
}

export def poetry-run-python [filename: string] {
    if ('.env.local' | | path exists) { 
        with-dot-env .env.local { poetry run python $filename }
    } else {
        poetry run python $filename
    }
}
