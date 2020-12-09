alias vbash="vim ~/.bashrc"
alias sbash=".   ~/.bashrc"

# open vim with tabs
alias vt="vim -p"
# open all vim files in a directory, with tabs
function vr {
    dir=$1
    if [[ -z $1 ]]; then
        dir='.';
    fi
    find $dir -xtype f -exec vim -p {} +
}

# My laptop config is set to `ssh $server && exit`
function x {
    if [[ -z $TMUX ]]; then
        exit 0
    else
        echo "Please quit Tmux with Cmd+w"
    fi
}
function xx {
    if [[ -z $TMUX ]]; then
        exit 1
    else
        echo "Please quit Tmux with Cmd+w"
    fi
}
