function unclean {
    dirsToCheck=("$@")
    singleDir=1
    if [[ "$#" -eq 0 ]]; then
        dirsToCheck="."
    elif [[ "$#" -ne 1 ]]; then
        singleDir=0
    fi

    anyUnclean=0
    owd=$PWD
    for dir in "${dirsToCheck[@]}"; do
        dest=$owd/$dir
        if [[ ! -d $dest ]]; then
            continue
        fi
        cd $dest

        output=""

        local_branches="$(gb | grep -v 'master\|main\|trunk')"
        if [[ ! -z $local_branches ]]; then
            output="Local branches:\n$local_branches\n\n"
        fi
        changed_files="$(git status --porcelain=v1 2>/dev/null)"
        if [[ ! -z $changed_files ]]; then
            output="${output}Uncommitted files:\n$changed_files\n\n"
        fi
        open_jobs=$(jobs)
        if [[ ! -z $open_jobs ]]; then
            output="${output}Jobs:\n$open_jobs\n\n"
        fi
        wip=$(gs list)
        if [[ ! -z $wip ]]; then
            output="${output}WIP:\n$wip\n\n"
        fi

        if [[ ! -z "$output" ]]; then
            anyUnclean=1
            if [[ $dir != "." ]]; then
                printf "$dir:\n"
            fi
            printf "$output"
        fi
    done

    cd $owd

    if [[ "$anyUnclean" -eq 1 && "$singleDir" -eq 1 ]]; then
        return 1
    fi

    return 0
}
