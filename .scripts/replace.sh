#!/bin/bash

# Because I'm lazy I don't want release.sh to run on every single dev build.
# Basic replacements can be done much faster here.
echo "Executing replace.sh $1 $2"
LOC=$1
classic=$2

replace_addon(){
   sed -i "s/GetAddon(\"RCLootCouncil\")/\GetAddon(\"RCLootCouncil_Classic\")/" "$1"
   echo "Addon replacement done $1 $classic"
}

lua_filter() {
	sed -i \
		-e "s/--@$1@/--[===[@$1@/g" \
		-e "s/--@end-$1@/--@end-$1@]===]/g" \
		-e "s/--\[===\[@non-$1@/--@non-$1@/g" \
		-e "s/--@end-non-$1@\]===\]/--@end-non-$1@/g" "$2"
}

# Inspired by 'release.sh', but reimplemented with 'awk'
toc_replace() {
   echo "Doing .toc replacements for $1 $2"
   _trf_action=1
	if [ "$2" = "true" ]; then
		_trf_action=0
	fi
   awk -v action=$_trf_action '
      BEGIN {
         keep=1         # Keep lines
         uncomment=0    # Uncomment lines
         skip=0         # Skip current line
      }
      /^#@retail@/{
         keep=action
         skip=1
      }
      /^#@non-retail@/{
         keep= 1 - action
         uncomment=1
         skip=1
      }
      /^#@end-/{
         keep=1
         uncomment=0
         skip=1
      }
      {
         if ( skip == 0 && keep == 1 )
         {
            if (uncomment == 1) {
               $1="" # Remove #
               sub(" ", "") # Remove the space after
            }
            print $0
         }
         skip = 0 # Reset
      }
   ' $1 > "${3}_tempToc"
   # Maybe find a better way to do this?
   cat "${3}_tempToc" > $1
   rm "${3}_tempToc"
}

if [[ -d "./.tmp" ]]; then
   find_cmd="find $LOC -name \"*.lua\" -o -name \"*.toc\" -o -path \"*/Locale\" -prune"
   eval $find_cmd | while read file; do
      case $file in
      *.lua)
         if [ "$classic" = "true" ]; then
           replace_addon $file
           lua_filter "retail" $file
         else # Retail
           lua_filter "non-retail" $file
         fi
         ;;
      *.toc)
         toc_replace $file $classic $LOC
      ;;
      esac
   done
else
   echo ".tmp folder doesn't exist - no replacements."
fi

echo "Replacements done."
