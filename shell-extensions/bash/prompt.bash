_prompt_UNDERLINE=4
_prompt_COLOR_PATH=32   # green
_prompt_COLOR_TICKET=36 # blue

prompt_pretty_path () {
    # I have $HOME/go/src/$work_url
    # symlinked to $HOME/gobucket
    # to enable this prettiness
    pwd -P | sed "s~^$HOME~\~~"
}

set_up_prompt() {
    PS1="\[\e]0;\u@\h:\w\007\][\$(date +%H:%M)] \h: \[\e[0;${_prompt_COLOR_PATH}m\]"'`prompt_pretty_path`'"\[\e[0m\]\[\e[0;${_prompt_COLOR_TICKET}m\] \${GIT_BRANCH}\[\e[0;00m\] \$ "
    PROMPT_COMMAND=$'GIT_BRANCH=$(current_git_branch)'

}

set_up_prompt
unset -f set_up_prompt
