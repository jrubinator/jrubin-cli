EXPORT_PATH=~/.jrubincli/navigation
MODE_FILE=$EXPORT_PATH/mode
mkdir -p $EXPORT_PATH
if [[ -s $EXPORT_PATH/mode ]]; then
    global_mode=`cat $MODE_FILE`
fi
export JRCLI_MODE="$global_mode"

function ch {
    dir="schema/changes/$(git_changeset)"
    branch=$(current_git_branch)
    changes=$(find $dir -name "$branch-*")

    e
    if [[ -n $changes ]]; then
        vim $changes
    else
        mkdir -p $dir && vim "$dir/$branch-before.sql"
    fi
}

function dep {
    e && vim "etc/dependencies/$(git_changeset)"
}

function e {
    perlScript=$(dirname "${BASH_SOURCE[0]}")/navigation.pl
    cd $(perl $perlScript $@)

}
