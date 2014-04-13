#!/usr/bin/env bash





# Define some color escape codes used later on
GREEN='\e[1;32m'
RED='\e[0;31m'
CYAN='\e[0;36m'
NC='\e[0m'
YELLOW='\e[1;33m'


DEPENDENCIES='cat sed grep ctorrent mktorrent mount df'



choose_drive_to_capture () {
	read -p "Please specify a drive to capture: [/dev/sd?|mount|df|dmesg|ls /dev]" option

	if [[ $option == "mount" ]] ; then
		mount
		return
	elif [[ $option == "df" ]] ; then
		df
		return
	elif [[ $option == "dmesg" ]] ; then
		dmesg | less
		return
	elif [[ $option == "ls /dev" ]] ; then
		ls /dev
		return
	else
		drive=$option
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
drive='/dev/null'
while [[ $drive == '/dev/null' ]] ; do
	choose_drive_to_capture
	if [[ ! -b $drive && $drive != '/dev/null' ]] ; then
		if [[ -f $drive ]] ; then
			echo -e "${RED}File $drive is not a block special device."
			echo -e "This might have unintended effects.${NC}"
			read -p "Do you wish to continue? [y|N] " option
			if [[ ! ( $option == "y" ||
			          $option == "Y" ||
			          $option == "yes" ) ]] ; then
				drive='/dev/null'
			fi
		else
			echo -e "${RED}File $drive does not exist.${NC}"
			drive='/dev/null'
		fi
	fi
done




