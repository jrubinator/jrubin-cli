function unclean {
    local_branches="$(gb | grep -v 'master\|main\|trunk')"
    if [[ ! -z $local_branches ]]; then
        printf "Local branches:\n$local_branches\n\n"
    fi
    changed_files="$(git status --porcelain=v1 2>/dev/null)"
    if [[ ! -z $changed_files ]]; then
        printf "Uncommitted files:\n$changed_files\n\n"
    fi
    open_jobs=$(jobs)
    if [[ ! -z $open_jobs ]]; then
        printf "Jobs:\n$open_jobs\n\n"
    fi
    wip=$(gs list)
    if [[ ! -z $wip ]]; then
        printf "WIP:\n$wip\n\n"
    fi

    if [[ ! -z "$local_branches$changed_files$open_jobs$wip" ]]; then
        return 1
    fi

    return 0
}
