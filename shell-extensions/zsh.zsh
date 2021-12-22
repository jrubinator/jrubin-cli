BASE_DIR="$( cd "$( dirname "${(%):-%N}" )" && pwd )"
SCRIPT_DIR="$BASE_DIR/../scripts"
export PATH="$SCRIPT_DIR/other:$SCRIPT_DIR/git:$SCRIPT_DIR/grep:$PATH"

for f in $BASE_DIR/zsh/*; do
    source $f
done
