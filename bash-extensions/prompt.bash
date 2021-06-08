export PROMPT_COMMAND='GIT_BRANCH=$(current_git_branch)'
export PS1='\[\e]0;\u@\h:\w\007\][$(date +%H:%M)] \h: \[\e[0;32m\]\w\[\e[0m\]\[\e[0;36m\] ${GIT_BRANCH}\[\e[0;00m\]\$ '
