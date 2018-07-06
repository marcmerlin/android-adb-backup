#!/bin/bash

# License; Apache-2

# Tested/Fixed for Android O by marc_soft@merlins.org 2017/12
# Added support for filenames/directories with spaces

# Example restore:
# for i in ch.ssigno.zoneminder com.aa.android com.alexvas.dvr.pro com.amazon.drive com.amazon.kindle com.amazon.mShop.android.shopping com.amazon.now com.audible.application com.camsam.plus com.crosschasm.evchargerlocator com.ds.avare com.eventbrite.attendee com.fltplan.go com.frogsparks.mytrails com.fvd com.garmin.android.apps.connectmobile com.gaudiumsoft.voiceimport com.geeksville.andropilot com.goodrx com.google.android.apps.aiuto com.google.android.apps.authenticator2 com.lifx.lifx com.nest.android com.pas.webcam com.rainmachine com.sony.playmemories.mobile com.southwestairlines.mobile com.teslamotors.tesla com.trailbehind.android.gaiagps.pro com.ubercab com.united.mobile.android com.wf.wellsfargomobile me.lyft.android org.mavlink.qgroundcontrol us.avnav.efb
# 

echo "Please use restore_apps.sh <dir> appname instead of this program, left for posterity"
exit 0

set -e   # fail early

A=adb

DRY="echo"

if [[ "$1" == "-f" ]]; then
    DRY=""
    shift
fi

DIR="$1"
if [[ ! -d "$DIR" ]]; then
	echo "Usage: $0 <date/data/data-dir> [-f]"
	echo "Must be created with ./backup_apps.sh"
	exit 2
fi

# Accept -f before or after the DIR argument
[[ "$2" == "-f" ]] && DRY=""

# Remove trailing / if any in DIR
DIR="${DIR%/}"

echo "## Restart adb as root"
$A root
sleep 3s

# Find if app is running
APP=`basename "$DIR"`

PS=( $(adb shell ps | grep -s $APP || /bin/true) )
PID=${PS[1]}

if [[ -n $PID ]]; then
    echo "## Kill app $APP at PID $PID"
    $DRY $A shell kill $PID
fi

# figure out current app user id
L=( $($A shell ls -d -l /data/data/$APP) )
# drwx------ 10 u0_a240 u0_a240 4096 2017-12-10 13:45 .
# => return u0_a240
ID=${L[2]}

if [[ -z $ID ]]; then
    echo "ERROR: can't find user-id of /data/data/$APP on device. Run app first."
    exit 2
fi

echo "APP User id is $ID"

echo
echo "## Pushing data"
echo

#$DRY $A push "$DIR" /data/data/$APP
$DRY $A push "$DIR" /data/data/

# support directories like "Crash Reports"
export IFS="
"
# TODO: this is terribly inefficient, one adb chown command per file restore
# is very slow if you have a package with hundreds of files.  
# Recursive chown on the top directory would be a lot faster, but I
# didn't investigate how safe it is -- merlin
for j in `find "$DIR" -printf "%P\n"`; do
    echo "Fixing permissions on $j"
    if [[ -d "$DIR/$j" ]]; then
	test -z "$DRY" && echo $A shell mkdir -p "/data/data/$APP/$j"
	$DRY $A shell "mkdir -p \"/data/data/$APP/$j\""
    fi
    test -z "$DRY" && echo $A shell chown $ID.$ID "/data/data/$APP/$j"
    $DRY $A shell chown $ID.$ID "\"/data/data/$APP/$j\""
done

[[ -n $DRY ]] && echo "=== This is DRY MODE. Use -f to actually copy."
