setopt interactivecomments

prompt_pretty_path () {
    # I have $HOME/go/src/$work_url
    # symlinked to $HOME/gobucket
    # to enable this prettiness
    pwd -P | sed "s~^$HOME~\~~"
}

set_up_prompt() {
    # zsh, this will override PS1
    autoload -Uz vcs_info
    precmd_vcs_info() { vcs_info }
    precmd_functions+=( precmd_vcs_info )
    setopt prompt_subst
    zstyle ':vcs_info:git:*' formats '%b'
    PROMPT='[%D{%K:%M}] %m %F{green}$(prompt_pretty_path)%f %F{cyan}${vcs_info_msg_0_}%f $ '
}

set_up_prompt
unset -f set_up_prompt
