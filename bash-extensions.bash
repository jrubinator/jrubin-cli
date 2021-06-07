# Source this file to source all files in bash-extensions
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for f in $BASE_DIR/bash-extensions/*; do
    source $f
done
