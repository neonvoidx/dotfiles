function _fnm_find_node_version_file -a path --description 'Find node version file in path'
    for filename in $argv
        if test -f "$path/$filename"
            echo "$path/$filename"
            break
        end
    end
end

function _fnm_find_node_version_file_up -a path --description 'Find node version file in parent directory recursively'
    set -l node_version_files $argv[2..-1]
    while test "$path" != /
        set -l maybe_file (_fnm_find_node_version_file $path $node_version_files)
        if set -q maybe_file[1]
            echo $maybe_file
            break
        end
        set path (path normalize "$path/..")
    end
end

function fnm_use --description 'Change node version'
    # do not run if fnm is not loaded, or we're in a command substitution
    test -z "$FNM_MULTISHELL_PATH" || status --is-command-substitution; and return 0

    set -l node_version_files .nvmrc .node_version
    test "$FNM_RESOLVE_ENGINES" = true; and set -p node_version_files package.json

    # check for node version files
    set -l node_version_file
    if test "$FNM_VERSION_FILE_STRATEGY" = local
        set node_version_file (_fnm_find_node_version_file $PWD $node_version_files)
    else if test "$FNM_VERSION_FILE_STRATEGY" = recursive
        set node_version_file (_fnm_find_node_version_file_up $PWD $node_version_files)
    end

    if set -q node_version_file[1]
        set -l mod_time (path mtime $node_version_file)
        # check if the found version file is different or newer than the one that is loaded
        if ! set -q _fnm_current_node_version_file[1] ||
                test "$_fnm_last_node_version_file[1]" != "$node_version_file" ||
                test $mod_time -gt $$_fnm_current_node_version_file[2]
            fnm use --silent-if-unchanged &&
                set -g _fnm_current_node_version_file $node_version_file $mod_time
        end
    else if set -q _fnm_current_node_version_file[1]
        # restore system node if no version files are found
        fnm use --silent-if-unchanged system
        set -e _fnm_current_node_version_file
    end
end

function _fnm_autoload_on_cd --on-variable PWD --description 'Change Node version on directory change'
    fnm_use
end

function _fnm_autoload_on_prompt --on-event fish_prompt --description 'Load Node version on first prompt'
    fnm_use
    functions -e _fnm_autoload_on_prompt
end
