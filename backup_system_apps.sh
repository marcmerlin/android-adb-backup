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
DIR="${HW}_${DATE}_${BUILD}_system"
if test -d "$DIR"; then
    echo "$DIR already exists, exiting"
    exit 2
fi
echo "### Creating dir $DIR"
$DRY mkdir -p $DIR
$DRY cd $DIR
$DRY mkdir -p data


echo "## Pull apps"

# Asec is gone in O?
#( mkdir -p asec ; cd asec ; $DRY adb pull /mnt/asec . || echo "### Failed to get /mnt/asec" )

# I'm ignoring com.qualcomm and com.verizon
# Ok, this is not the right way to do it, but works well enough for me
# it will backup some non system apps that happen to have a name root
# similar to system apps. Not great, but I can live with it.
# Better would be to make a list of all apps in /data/data that do not
# have a matchin apk in /data/app/
for i in `$A shell echo /data/data/com.{google.android*,android*}` ; do
	i="$(basename $i)"
	echo $i
	$DRY mkdir -p data/$i
	$DRY $A pull /data/data/$i data || echo "### Failed for $i"
done


echo "## Restart Runtime" && $DRY $A shell start
[[ $DRY ]] && echo "DRY RUN ONLY! Use $0 -f to actually download."
