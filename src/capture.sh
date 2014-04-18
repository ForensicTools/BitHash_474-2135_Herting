#!/bin/bash

#################################################################################
# The MIT License (MIT)                                                         #
#                                                                               #
# Copyright (c) 2013, 2014 Aaron Herting "qwertos" <aaron@herting.cc>           #
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


# Set preset values for options
DEBUG='false'


# Define some color escape codes used later on
GREEN='\e[1;32m'
RED='\e[0;31m'
CYAN='\e[0;36m'
NC='\e[0m'
YELLOW='\e[1;33m'


# Clear the screen
clear


# Parse options for btcapture.
# These were set when the kernel was called. The options are
# located in /proc/cmdline
echo -e "${CYAN}Parse options...${NC}"
for option in `cat /proc/cmdline`; do 
	key=`echo $option | cut -d= -f1`
	value=`echo $option | cut -d= -f2`
	echo -n 'key: '
	echo -n "$key"
	echo -ne "\t"
	echo -n 'value: '
	echo $value

	if [[ $key == 'bt-email' ]] ; then
		echo -n "$value" > /tmp/email.addr
	fi

	if [[ $key == 'bt-email_server' ]] ; then
		echo -n "$value" > /tmp/email.server
	fi

	if [[ $key == 'bt-email_user' ]] ; then
		echo -n "$value" > /tmp/email.user
	fi

	if [[ $key == 'bt-cache_uuid' ]] ; then
		echo -n "$value" > /tmp/cache.uuid
	fi

	if [[ $key == 'bt-comment' ]] ; then
		echo -n "$value" > /tmp/comment.txt
	fi

	if [[ $key == 'bt-tracker' ]] ; then
		echo -n "$value" > /tmp/tracker.url
	fi

	if [[ $key == 'bt-ctcs' ]] ; then
		echo -n "$value" > /tmp/ctcs.srv
	fi

	if [[ $key == 'bt-debug' ]] ; then
		DEBUG='true'
	fi

	if [[ $key == 'bt-submit_key' ]] ; then
		echo -n "$value" > /tmp/submit_key.txt
	fi

done

echo -e "${CYAN}Parse options... [ ${GREEN}DONE${CYAN} ]${NC}"


# Confirm the required options were parced correctly
echo -e "${CYAN}Checking for parced options...${NC}"
if [[ ! -f /tmp/cache.uuid ]] ; then
	echo -e "${CYAN}Checking for parced options... [ ${RED}FAIL${CYAN} ]${NC}"
	echo -e "${RED}MISSING: /tmp/cache.uuid${NC}"
	exit 404
fi

if [[ ! -f /tmp/ctcs.srv ]] ; then
	echo -e "${CYAN}Checking for parced options... [ ${RED}FAIL${CYAN} ]${NC}"
	echo -e "${RED}MISSING: /tmp/ctcs.srv${NC}"
	exit 404
fi

if [[ ! -f /tmp/comment.txt ]] ; then
	echo -e "${CYAN}Checking for parced options... [ ${RED}FAIL${CYAN} ]${NC}"
	echo -e "${RED}MISSING: /tmp/comment.txt${NC}"
	exit 404
fi

if [[ ! -f /tmp/tracker.url ]] ; then
	echo -e "${CYAN}Checking for parced options... [ ${RED}FAIL${CYAN} ]${NC}"
	echo -e "${RED}MISSING: /tmp/tracker.url${NC}"
	exit 404
fi

if [[ ! -f /tmp/email.addr ]] ; then

	echo -e "${CYAN}Checking for parced options... [ ${RED}FAIL${CYAN} ]${NC}"
	echo -e "${RED}MISSING: /tmp/email.addr${NC}"
	exit 404
fi

if [[ ! -f /tmp/email.server ]] ; then

	echo -e "${CYAN}Checking for parced options... [ ${RED}FAIL${CYAN} ]${NC}"
	echo -e "${RED}MISSING: /tmp/email.server${NC}"
	exit 404
fi

if [[ ! -f /tmp/email.user ]] ; then

	echo -e "${CYAN}Checking for parced options... [ ${RED}FAIL${CYAN} ]${NC}"
	echo -e "${RED}MISSING: /tmp/email.user${NC}"
	exit 404
fi
echo -e "${CYAN}Checking for parced options... [ ${GREEN}DONE${CYAN} ]${NC}"


# Mount the drive to cache the img file pre-torrent generation
echo -e "${CYAN}Mounting cache drive...${NC}"
# Ensure mount point exists
mkdir -p /mnt/cache
# Mount the drive
mount UUID=`cat /tmp/cache.uuid` /mnt/cache

# Check to see if the file /mnt/cache/IMAGING_DRIVE exists.
# This is a sanity check to ensure you actually want to write to
# this drive. Nothing needs to be in it, just needs to exist.
if [[ ! -f /mnt/cache/IMAGING_DRIVE ]] ; then
	echo -e "${CYAN}Mounting cache drive... [ ${RED}FAIL${CYAN} ]${NC}"
	echo -e "${RED}MISSING: /mnt/cache/IMAGING_DRIVE${NC}"
	exit 2
fi
df -h 
echo -e "${CYAN}Mounting cache drive... [ ${GREEN}DONE${CYAN} ]${NC}"


# Calculating the parameters for dd. Will only grab 
# the number of bytes until the last byte of the last
# partition on /dev/sda (generally) + 2 blocks for safety.
echo -e "${CYAN}Calculating parameters for dd...${NC}"
CACHE_PART=`blkid -U $( cat /tmp/cache.uuid )`

if [[ $DEBUG == 'true' ]] ; then
	echo -e "${YELLOW}CACHE_PART = ${CACHE_PART}${NC}"
fi

CACHE_DEV=`echo "$CACHE_PART" | sed 's/[0-9]//g'`

if [[ $DEBUG == 'true' ]] ; then
	echo -e "${YELLOW}CACHE_DEV = ${CACHE_DEV}${NC}"
fi

echo -n "$CACHE_DEV" > /tmp/cache.dev

DRIVES=`ls -1 /dev/sd? | grep -v "$CACHE_DEV"`

if [[ $DEBUG == 'true' ]] ; then
	echo -e "${YELLOW}DRIVES = ${DRIVES}${NC}"
fi

DRIVE_TO_CAPTURE=`echo "$DRIVES" | head -n 1`

if [[ $DEBUG == 'true' ]] ; then
	echo -e "${YELLOW}DRIVE_TO_CAPTURE = ${DRIVE_TO_CAPTURE}${NC}"
fi

echo -n "$DRIVE_TO_CAPTURE" > /tmp/src.dev


#LAST_BLOCK=`parted -s "$DRIVE_TO_IMAGE" unit s print | 
LAST_BLOCK=`fdisk -lu $DRIVE_TO_CAPTURE | sed 's/\(\(*\)\|\(Boot\)\)//g' | awk '{print $3}' | tail -n 1 | awk '{print $1 + 2}'`

if [[ $DEBUG == 'true' ]] ; then
	echo -e "${YELLOW}LAST_BLOCK = ${LAST_BLOCK}${NC}"
fi

IMAGE_FILE="/mnt/cache/`cat /tmp/comment.txt`.`date +%s`.img"

if [[ $DEBUG == 'true' ]] ; then
	echo -e "${YELLOW}IMAGE_FILE = ${IMAGE_FILE}${NC}"
fi

TOTAL_KBYTES=$[LAST_BLOCK / 2]

if [[ $DEBUG == 'true' ]] ; then
	echo -e "${YELLOW}TOTAL_KBYTES = ${TOTAL_KBYTES}${NC}"
fi

echo -e "${CYAN}Calculating parameters for dd... [ ${GREEN}DONE${CYAN} ]${NC}"


# Copies the drive to a .img file located on /mnt/cache
echo -e "${CYAN}Copying drive...${NC}"

#dd if="$DRIVE_TO_CAPTURE" of="$IMAGE_FILE" bs=512 count="$LAST_BLOCK"
# Adds progress bar
dd if="$DRIVE_TO_CAPTURE" bs=512 count="$LAST_BLOCK" | pv -s "${TOTAL_KBYTES}K" | dd of="$IMAGE_FILE"

echo -e "${CYAN}Copying drive... [ ${GREEN}DONE${CYAN} ]${NC}"


# Generates torrent file
echo -e "${CYAN}Generating torrent...${NC}"
BASE_NAME=`basename "$IMAGE_FILE"`
cd /mnt/cache
# Single threaded
#/usr/local/bin/ctorrent -t -u `cat /tmp/tracker.url` -p -c `cat /tmp/comment.txt` -s "$BASE_NAME.torrent" -l 4194304 $BASE_NAME
# Multithreaded
# TODO: vv Test this line
/usr/local/bin/mktorrent -a `cat /tmp/tracker.url` -c `cat /tmp/comment.txt` -l 22 -p -v $BASE_NAME
echo -e "${CYAN}Generating torrent... [ ${GREEN}DONE${CYAN} ]${NC}"



echo -e "${CYAN}Notifying and serving torrent file...${NC}"

# Adds the torrent file to the local webserver
cp "$IMAGE_FILE.torrent" /var/www/$BASE_NAME.torrent

# Get the local ip address to send in email 
ip=`/usr/local/bin/getip.sh | tail -n 1`

remote_command="wget http://$ip/$BASE_NAME.torrent"

# Sends email with the torrent file as an attachment as
# well as a link to the file hosted on the local webserver
(
	echo "Subject: Torrent file is ready"
	echo
	echo "comment"
	cat /tmp/comment.txt
	echo
	echo "Download the torrent file by running:"
	echo $remote_command
	echo
	cat "$IMAGE_FILE.torrent" | uuencode "$BASE_NAME.torrent" 
) | sendmail -f `cat /tmp/email.user` -S `cat /tmp/email.server` `cat /tmp/email.addr`

# Not yet implimented
#wget "http://tracker.ce.rit.edu/submit.php?submit_key=`cat /tmp/submit_key.txt`&file=$BASE_NAME.torrent"


echo -n "$IMAGE_FILE" > /tmp/drive.path

echo -e "${CYAN}Notifying and serving torrent file... [ ${GREEN}DONE${CYAN} ]${NC}"


CTORRENT_SEED_OPTIONS="-p 51413 -S `cat /tmp/ctcs.srv` -s $IMAGE_FILE -r $IMAGE_FILE.torrent -A cTorrent-image_capture/dnh3.3.2-patched"

echo -e "${CYAN}Seeding...${NC}"
/usr/local/bin/ctorrent $CTORRENT_SEED_OPTIONS
echo -e "${RED}YOU SHOULD NOT SEE ME... SOMETHING PROBABLY WENT WRONG${NC}"

