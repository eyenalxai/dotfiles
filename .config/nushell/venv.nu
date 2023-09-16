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

def is-string [x] {
    ($x | describe) == 'string'
}

def has-env [name: string, _env: record] {
    $name in ($_env)
}

def get-new-lib-dirs [env: record] {
    if not $env.PWD in $env.NU_LIB_DIRS { return ($env.NU_LIB_DIRS | prepend $env.PWD) } 
    
    return $env.NU_LIB_DIRS
}

def-env deactivate-venv [_env: record] {
    hide-env VIRTUAL_ENV    
    
    load-env {
        PATH: $_env.PATH,
        NU_LIB_DIRS: $_env.NU_LIB_DIRS
    }
}

def-env activate-venv [_env: record, virtual_env: string] {
    let bin = ([$virtual_env, "bin"] | path join)
    
    let old_path = $_env.PATH
    let venv_path = ([$virtual_env $bin] | path join)
    let new_path = ($old_path | prepend $venv_path)
    
    let new_lib_dirs = get-new-lib-dirs $_env

    load-env {
        PATH: $new_path
        VIRTUAL_ENV: $virtual_env
        NU_LIB_DIRS: $new_lib_dirs
    }
}

export def-env auto-venv-toggle [_env: record] {
    let find_closest_venv_result = find-closest-dir ".venv"

    if ($find_closest_venv_result | is-empty) == true {
        if ('VIRTUAL_ENV' in $env) == true {
            deactivate-venv $_env
        }
        return
    }
    
    if ('VIRTUAL_ENV' in $env) == false {
        activate-venv $_env ($find_closest_venv_result | first)
    }
}


