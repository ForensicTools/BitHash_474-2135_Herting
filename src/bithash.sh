#!/usr/bin/env bash


#################################################################################
# The MIT License (MIT)                                                         #
#                                                                               #
# Copyright (c) 2014, Aaron Herting "qwertos" <aaron@herting.cc>                #
#                                                                               #
# Permission is hereby granted, free of charge, to any person obtaining a copy  #
# of this software and associated documentation files (the "Software"), to deal #
# in the Software without restriction, including without limitation the rights  #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     #
# copies of the Software, and to permit persons to whom the Software is         #
# furnished to do so, subject to the following conditions:                      #
#                                                                               #
# The above copyright notice and this permission notice shall be included in    #
# all copies or substantial portions of the Software.                           #
#                                                                               #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     #
# THE SOFTWARE.                                                                 #
#################################################################################



# Define some color escape codes used later on
GREEN='\e[1;32m'
RED='\e[0;31m'
CYAN='\e[0;36m'
NC='\e[0m'
YELLOW='\e[1;33m'


DEPENDENCIES='cat sed grep ctorrent mktorrent mount df sudo umount read'



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

if mount | grep $drive &> /dev/null ; then
	echo -e "${RED}$drive is currently mounted."
	echo -e "This might have uninteneded effects.${NC}"
	read -p "Would you like to unmount the drive? [Y|n] " option
	if [[ ! ( $option == "n" ||
	          $option == "N" ||
	          $option == "no" ) ]] ; then

		sudo umount $drive

		if mount | grep $drive &> /dev/null ; then
			echo -e "${RED}$drive is still mounted. Unmount attempt failed."
			echo -e "Exiting...${NC}"
			exit 1
		else
			echo -e "${GREEN}$drive was unmounted${NC}"
		fi
	fi
else
	echo -e "${GREEN}$drive is not mounted ${NC}"
fi


workspace=""
while [[ $workspace == "" ]] ; do
	read -p "Enter a directory to act as a workspace: (default- pwd) " option

	if [[ $option == "" ]] ; then
		$option == `pwd`
	fi
		

	if [[ -d $option ]] ; then
		if [[ ! ( -x $option &&
		          -w $option &&
		          -r $option )) ]] ; then
			echo -e "${RED}You do not have full permissions in the directory"
			echo -e "$option. Please choose a directory where you have"
			echo -e "full permissions.${NC}"

			workspace=""
		else
			workspace=$option
		fi
	fi
done



