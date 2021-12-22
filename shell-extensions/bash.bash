# Source this file to source all files in bash-extensions
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR="$BASE_DIR/../scripts"
export PATH="$SCRIPT_DIR/other:$SCRIPT_DIR/git:$SCRIPT_DIR/grep:$PATH"

for f in $BASE_DIR/bash/*.bash; do
    source $f
done
