#!/bin/sh

# Because I'm lazy I don't want release.sh to run on every single dev build.
# Basic replacements can be done much faster here.
echo "Executing replace.sh $1 $2"
LOC=$1
classic=$2

replace_addon(){
   ls -rt ./$LOC/*.lua | xargs sed -i "s/GetAddon(\"RCLootCouncil\")/\GetAddon(\"RCLootCouncil_Classic\")/"
   echo "Addon replacement done $LOC $classic"
}

if [[ -d "./.tmp" ]]; then
   if [ "$classic" = "true" ]; then
      replace_addon
   fi
else
   echo ".tmp folder doesn't exist - no replacements."
fi

echo "Replacements done."
