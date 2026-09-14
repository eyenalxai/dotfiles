def --env --wrapped rift [...rest] {
  match ($rest | get 0? | default "" | into string) {
    "init" | "create" | "remove" => {
      let cwd = (^r#'/usr/bin/rift'# --shell-cwd ...$rest | str trim)
      if ($cwd | is-not-empty) {
        cd $cwd
      }
    }
    _ => {
      ^r#'/usr/bin/rift'# ...$rest
    }
  }
}
