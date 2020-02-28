#!/bin/bash
# This file will copy files located in the toplevel folder of the caller, and paste them in WoW Addon directory.
# Assumes a ".env" located next to this file or at top level which contains a variable "WOW_LOCATION" pointing
# to the WoW install location. It also assumes the toplevel folder is named after the addon.
#
# All files and folders starting with "." or "__" are exluded from the deploy, and only updates are copied.
# Files that no longer exists in the SOURCE are deleted from the DESTINATION.
#
# It uses `robocopy` to do the file/folder filtering, however a `cp` without filtering is commented out.
echo "Executing $0" >&2

# Process command-line options
usage() {
	echo "Usage: test.sh [-cp]" >&2
	echo "  -c               Pack to _classic_ WoW edition." >&2
	echo "  -p               Pack to _ptr_ WoW edition." >&2
}

ADDON_LOC="$(pwd)"
ADDON="$(basename $ADDON_LOC)"
WOWEDITION="_retail_"
is_classic=false

# Commandline inputs
while getopts ":cp" opt; do
	case $opt in
      c)
         WOWEDITION="_classic_"
			is_classic=true;;
      p)
         WOWEDITION="_ptr_";;
      /?)
         usage ;;
   esac
done

# Check .env
if [ -f ".env" ]; then
 . "./.env"
elif [[ -f ".scripts/.env" ]]; then
   . ".scripts/.env"
else
   echo "<WARNING> Couldn't find \".env\" file. This should contain a WOW_LOCATION variable with the game path.">&2
fi

if [ -z "$WOW_LOCATION" ]; then
   echo "<ERROR> Expected \$WOW_LOCATION to be set, cannot deploy." >&2
   echo "Exiting..."
   exit;
fi

TEMP_DEST=".tmp/$ADDON"
DEST="$WOW_LOCATION$WOWEDITION/Interface/AddOns/$ADDON"

# Copy to temp folder:
# cp "$ADDON_LOC" "$TEMP_DEST" -ruv
robocopy "$ADDON_LOC" "$TEMP_DEST" //s //purge //XD .* __* $(sed "s/^/  /" .gitignore) //XF ?.* __*

# Do file replacements.
. "./.scripts/replace.sh" "$TEMP_DEST" "$is_classic"

robocopy "$TEMP_DEST" "$DEST" //s //purge //XD .* __*  //XF ?.* __* //NFL //NDL //NJH

rm -r ".tmp/"
echo "Finished deploying $ADDON"
