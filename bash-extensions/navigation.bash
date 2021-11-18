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
    perlDir=$(perl $perlScript $@)
    echo "Using perl, would have cd'ed to '$perlDir'"

    if [[ $# < 1 ]]; then
        _e
    else
      #  (slack &)
        local diving_board=$(pwd)
        change_base $@
        # if we changed between the same git repo in different structures
        # try to stay at the same level
        if [[ ! $diving_board =~ ^$HOME/$base/ ]]; then
            if [[ $diving_board =~ /$project/(.*)$ ]]; then
                cd ${BASH_REMATCH[1]}
            fi
        fi
        apply_any_patches
    fi
}

# XXX not sure the below comment is still true with e defined above
# This needs to be a function, or the e function wouldn't call it properly
# http://superuser.com/questions/708462/alias-scoping-in-bash-functions
function _e {
    cd $_jrubin_navigation_base/$1
}

function po {
    vim $_jrubin_navigation_base/share/locale/es/LC_MESSAGES/*.po && \
    make lexicon
}

function ee {
    perlScript=$(dirname "${BASH_SOURCE[0]}")/navigation.pl
    perlDir=$(perl $perlScript $@)

    IFS='-' read -r -a jrubin_export_pathparts <<< "$perlDir"
    local jrubin_export_path=''
    for pathpart in "${jrubin_export_pathparts[@]}"; do
        if [[ $pathpart == 'gsg' ]]; then
            pathpart='GSG';
        else
            pathpart="$(echo "$pathpart" | sed 's/.*/\u&/')"
        fi
        jrubin_export_path="$jrubin_export_path/$pathpart"
    done

    jrubin_export_path="$HOME/$base/$project/lib$jrubin_export_path"
    if [[ -d $jrubin_export_path ]]; then
        cd $jrubin_export_path;
    else
        >&2 echo "Repo name doesn't support ee"
    fi
}

function change_base  {
    function apply_any_patches {
        shopt -s nullglob
        for patch in ~/jrubin/export/patches/*; do
            git apply $patch && rm $patch
        done
        shopt -u nullglob
    }

    local base=""
    local global=0
    local mode=""
    local project=$1
    shift

    while [[ $# > 0 ]]; do
        key="$1"
        shift

        case $key in
            -g|--global)
                global=1
            ;;
            -b|--base)
                base=~/$1
                shift
                if [[ ${#base} < 1 ]]; then
                    >&2 echo "  You must specify a base!"
                    return
                elif [[ ! -d $base ]]; then
                    >&2 echo "  $base doesn't seem to exist!"
                    return
                fi

                export EXP_BASE="$base"
            ;;
            -m|--mode)
                mode="$1"
                shift
                export JRCLI_MODE="$mode"
                echo $mode > ~/jrubin/export/mode
            ;;
            -f|--file|--file-path)
                file_to_move="$1"
                if [[ ! -f ./$file_to_move && ! -d ./$file_to_move ]]; then
                    >&2 echo "  $file_to_move doesn't seem to exist!"
                    unset $file_to_move
                else
                    patch_dir=~/jrubin/export/patches
                    # Replace / with _ in filename
                    patch_file="${file_to_move//\//_}.patch"
                    mkdir -p $patch_dir
                    git diff $file_to_move > $patch_dir/$patch_file
                fi
            ;;
        esac
    done

    if [[ ${#base} > 1 ]]; then
        bases_to_check=($base)
    else
        base="$EXP_BASE"
        if [[ ${#base} < 1 ]]; then
            base='work'
        fi
        bases_to_check=($base ~/work ~/alt $(ls -d ~/go/src/*/*))
    fi

    debug="Exporting $project ($base)"
    if [[ -n $JRCLI_MODE ]]; then
        debug="$debug (mode: $JRCLI_MODE)"
    fi
    echo "$debug:"

    if ! [[ -d $base/$project ]]; then
        newproject=''
        newbase=''

        for base_to_check in ${bases_to_check[*]}; do

            if [[ -d $base_to_check/$project ]]; then
                newproject=$project
            # Try with mode
            elif [[ -d $base_to_check/$JRCLI_MODE-$project ]]; then
                newproject=$JRCLI_MODE-$project
            else
                for path in $base_to_check/$JRCLI_MODE-$project*; do
                    if [[ -d $path ]]; then
                        if [[ -n $newproject ]]; then
                            is_perl_rx='-(perl|carton)$'
                            if [[ $path =~ $is_perl_rx ]]; then
                                # Ignore the less-specific perl path
                                true
                            elif [[ $newproject =~ $is_perl_rx ]]; then
                                if ! [[ $path =~ $is_perl_rx ]]; then
                                    shouldquit=false
                                    newproject=$(basename $path)
                                fi
                            else
                                >&2 echo "  $project is not specific enough!"
                                return
                            fi
                        else
                            newproject=$(basename $path)
                        fi

                    fi
                done
            fi

            # Try no $mode at all
            if [[ -z $newproject ]]; then
                for path in $base_to_check/$project*; do
                    if [[ -d $path ]]; then
                        if [[ -n $newproject ]]; then
                            is_perl_rx='-(perl|carton)$'
                            if [[ $path =~ $is_perl_rx ]]; then
                                # Ignore the less-specific perl path
                                true
                            elif [[ $newproject =~ $is_perl_rx ]]; then
                                if ! [[ $path =~ $is_perl_rx ]]; then
                                    shouldquit=false
                                    newproject=$(basename $path)
                                fi
                            else
                                >&2 echo "  $project is not specific enough!"
                                return
                            fi
                        else
                            newproject=$(basename $path)
                        fi
                    fi
                done
            fi

            # Try mode without -
            if [[ -z $newproject ]]; then
                for path in $base_to_check/$JRCLI_MODE$project*; do
                    if [[ -d $path ]]; then
                        if [[ -n $newproject ]]; then
                            >&2 echo "  $project is not specific enough!"
                            return
                        else
                            newproject=$(basename $path)
                        fi
                    fi
                done
            fi

            if [[ -n $newproject ]]; then
                newbase=$base_to_check
                project=$newproject
                if [[ -z $mode ]]; then
                    if [[ $project =~ ^gsgx ]]; then
                        mode=gsgx
                    elif [[ $project =~ ^gsg ]]; then
                        mode=gsg
                    fi
                fi

                if [[ -n $mode ]]; then
                    export JRCLI_MODE="$mode"
                    echo $mode > $MODE_FILE
                fi
                break
            fi
            # else try another base
        done

        if [[ -z $newbase ]]; then
            >&2 echo "  $project doesn't seem to exist"
            return
        else
            base=$newbase
            export EXP_BASE="$newbase"
        fi
    fi

    if [[ -s ~/jrubin/export/$project.sh ]]; then
        . ~/jrubin/export/$project.sh;
    fi

    alias eb="_e bin"
    alias el="_e lib"
    alias es="_e schema"
    alias et="_e t"
    alias ett="_e template"
    alias ed="em"

    if [[ $global = 1 ]]; then
        echo $project > ~/jrubin/export/project
    fi


    _jrubin_navigation_base="$base/$project"
    _e
}
