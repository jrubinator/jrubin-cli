function jtmux {
    sess=$1
    tmux has -t $1 2> /dev/null
    if [[ -n $? ]]; then
        tmux new -d -s $sess  -n sb
        tmux new-w -t $sess:2 -n ut
        tmux new-w -t $sess:3 -n test
        tmux new-w -t $sess:4 -n lib
        tmux new-w -t $sess:5 -n 3rd
    fi
    tmux a -t $1
}
