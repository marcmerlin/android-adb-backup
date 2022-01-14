#!/bin/bash

# License; Apache-2

# Originally from Raphael Moll
# Tested/Fixed for Android O by marc_soft@merlins.org 2017/12

set -e   # fail early

if [[ "$1" == "-d" ]]; then shift;  DRY="echo" ; fi
DRY=""

A="adb -d"

echo "## Restart adb as root"
$DRY $A root
$DRY sleep 3s
echo "## Stop Runtime" && $DRY $A shell stop

HW=`$A shell getprop ro.hardware | tr -d '\r'`
BUILD=`$A shell getprop ro.build.id | tr -d '\r'`

DATE=`date +%F`
DIR="${HW}_${DATE}_${BUILD}"
if test -d "$DIR"; then
    echo "$DIR already exists, exiting"
    exit 2
fi

echo "### Creating dir $DIR"
$DRY mkdir -p $DIR
$DRY cd $DIR
$DRY mkdir -p app
$DRY mkdir -p data


echo "## Pull apps"

# Asec is gone in O?
#( mkdir -p asec ; cd asec ; $DRY adb pull /mnt/asec . || echo "### Failed to get /mnt/asec" )

# This does not work anymore:
#for APP in app app-private; do
#
#	for i in `$A shell ls /data/$APP | tr -d "\r" ` ; do
#		echo $i
#		$DRY $A pull /data/$APP/$i $APP/$i
#		d=${i%.apk}
#		d=${d%.zip}
#		d=${d%-[1-9]}
#		# /data/app/org.openintents.filemanager-0lGhieUsRc8H0LTGv2DyYQ==
#		# ccc71.at.free-cEQUrmG-8tLASwXXJi-03Q==
#		d=${d%%-*==}
#		$DRY mkdir -p data/$d
#		#$DRY $A pull /data/data/$d data/$d || echo "### Failed for $d"
#		$DRY $A pull /data/data/$d data || echo "### Failed for $d"
#	done
#
#done
adb pull /data/data
adb pull /data/app
rm -rf data/*/cache/*

echo "## Restart Runtime" && $DRY $A shell start
[[ $DRY ]] && echo "DRY RUN ONLY! Use $0 -f to actually download."
