#!/bin/sh
echo "Executing a $0"
release_script="./.scripts/release.sh"

"$release_script" -r "$(pwd)/.tmp/Retail" -doz
"$release_script" -r "$(pwd)/.tmp/Classic" -doz -g 1.13.4
