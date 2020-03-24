#!/bin/sh
echo "Executing a $0"
release_script=$(curl -s "https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh")


# # -d: Skip Upload
# # -z: Skip zip
echo "$release_script" | bash -s -- -r "$(pwd)/.tmp/Retail" -do
echo "$release_script" | bash -s -- -r "$(pwd)/.tmp/Classic" -do -g 1.13.4

# # Move the zip(s)
mv ./.tmp/Retail/*.zip "./.release/"
mv ./.tmp/Classic/*.zip "./.release/"
#
# # And delete .tmp
rm -r "./.tmp"

# read
