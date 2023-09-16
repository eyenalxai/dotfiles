def find-closest-dir [target: string, dir?: string] {
    # 1: split the directory into subdirs
    ($dir | default $env.PWD)
    | path split 
    | range 1.. 
    | reduce -f [($env.PWD | path split | first)] {|subdir, acc|
        $acc 
        | append ([($acc | last) $subdir] | path join ) 
    } 
    # 2: reverse the subdirs so thet the first is the "closest"
    | reverse 
    # 3: filter subdirs where the target exists
    | where {|subdir| 
        [$subdir $target] | path join | path exists
    }
    # 4. get subdir\target
    | each {[$in $target] | path join }
}

export def-env auto-venv-on-enter [_env: record] {
    def is-string [x] {
        ($x | describe) == 'string'
    }

    def has-env [name: string] {
        $name in ($_env)
    }

    let virtual_env    = find-closest-dir ".venv" | first
    let bin            = ([$virtual_env, "bin"] | path join)
    let virtual_prompt = ""

    let is_windows = ((sys).host.name | str downcase) == 'windows'
    let path_name = "PATH"

    let old_path = (
      $_env.PATH | if (is-string $in) {
          # if PATH is a string, make it a list
          $in | split row '/' | path expand
      } else {
          $in
      }
    )


    let venv_path = ([$virtual_env $bin] | path join)
    let new_path = ($old_path | prepend $venv_path)

    # Creating the new prompt for the session
    let virtual_prompt = if ($virtual_prompt == '') {
        $'(char lparen)($virtual_env | path split | drop 1 | path join | path basename)(char rparen) '
    } else {
        '(' + $virtual_prompt + ') '
    }

    let old_prompt_command = if (has-env 'PROMPT_COMMAND') {
        $_env.PROMPT_COMMAND
    } else {
        ''
    }

    # If there is no default prompt, then only the env is printed in the prompt
    let new_prompt = if (has-env 'PROMPT_COMMAND') {
        if (($old_prompt_command | describe) in ['block', 'closure']) {
            $'($virtual_prompt)(do $old_prompt_command)'
        } else {
            $'($virtual_prompt)($old_prompt_command)'
        }
    } else {
        $'($virtual_prompt)'
    }

    # Add current PWD to NU_LIB_DIRS so we can enter sub-directory without an error
    let new_lib_dirs = if not $env.PWD in $env.NU_LIB_DIRS {
        $env.NU_LIB_DIRS | prepend $env.PWD
    } else {
        $env.NU_LIB_DIRS
    }
    # Environment variables that will be batched loaded to the virtual env
    let new_env = {
        $path_name     : $new_path
        VIRTUAL_ENV    : $virtual_env
        PROMPT_COMMAND : $new_prompt
        VIRTUAL_PROMPT : $virtual_prompt
        NU_LIB_DIRS    : $new_lib_dirs
    }

    # Activate the environment variables
    print $new_env
    load-env $new_env
}


export alias pydoc = python -m pydoc
export alias pip   = python -m pip
