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

export def start_zellij [] {
  if 'ZELLIJ' not-in ($env | columns) {
    if 'ZELLIJ_AUTO_ATTACH' in ($env | columns) and $env.ZELLIJ_AUTO_ATTACH == 'true' {
      zellij attach -c
    } else {
      zellij
    }

    if 'ZELLIJ_AUTO_EXIT' in ($env | columns) and $env.ZELLIJ_AUTO_EXIT == 'true' {
      exit
    }
  }
}

