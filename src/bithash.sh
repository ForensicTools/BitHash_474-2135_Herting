#!/usr/bin/env bash





# Define some color escape codes used later on
GREEN='\e[1;32m'
RED='\e[0;31m'
CYAN='\e[0;36m'
NC='\e[0m'
YELLOW='\e[1;33m'


DEPENDENCIES='cat sed grep ctorrent mktorrent mount df'



choose_drive_to_capture () {
	read -p "Please specify a drive to capture: [/dev/sd?|mount|df|dmesg]" option

	if [[ $option == "mount" ]] ; then
		mount
		return choose_drive_to_capture
	elif [[ $option == "df" ]] ; then
		mount
		return choose_drive_to_capture
	elif [[ $option == "dmesg" ]] ; then
		dmesg | less
		return choose_drive_to_capture
	else
		return $option
	fi
}






# Dependancy checking.

dep_check_single () {
  BIN=$1
  
  echo -n "Checking for $BIN ... "
  if which $BIN > /dev/null 2> /dev/null ; then
    echo -e "[ ${GREEN}OK${NC} ]"
  else
    echo -e "[${RED}FAIL${NC}]"
    exit 2
  fi  
}


dep_check () {
  for dep in $DEPENDENCIES ; do
    dep_check_single $dep
  done
}


dep_check

echo `choose_drive_to_capture`


