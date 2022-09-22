#!/bin/bash

# License; Apache-2

# Tested/Fixed for Android S by marc_soft@merlins.org 2022/01
# Added support for filenames/directories with spaces

# Run a restore like this:
# ./restore_apps.sh --doit barbet_2022-01-12_SP2A.220107.001 org.droidplanner.services.android org.nick.kanjirecognizer org.opencpn.opencpn_free org.subsurface org.thoughtcrime.securesms org.videolan.vlc
# or
# ./restore_apps.sh --doit barbet_2022-01-12_SP2A.220107.001 `cat app_data_to_restore.txt`
#


set -e   # fail early

A="adb -d"
OLDIFS="$IFS"

DRY="echo"
if [[ "$1" == "--doit" ]]; then 
	DRY="" 
	shift
else
cat <<EOF
WARNING: restoring random system apps is quite likely to make things worse
unless you are copying between 2 identical devices.
You probably want to mv backupdir/data/{com.android,com.google}* /backup/location
This will cause this script not to try and restore system app data

EOF
sleep 3
fi
DIR="$1"

if [[ ! -d "$DIR" ]]; then
	echo "Usage: $0 [--doit] <date-dir>"
	echo "Must be created with ./backup_apps.sh"
	echo "Will be dry run by default unless --doit is given"
	exit 2
fi
shift


cd $DIR

if [ $# -gt 0 ]; then
	APPS="$@"
	echo "## Push apps: $APPS"
else
	APPS=$(echo data/*)
	echo "## Push all apps in $DIR: $APPS"
fi

echo "## Restart adb as root"
$DRY $A root
$DRY sleep 3

echo "## Install missing apps: $APPS"
for APP in $APPS
do
	echo "Installing $APP"
	#if ! $A shell ls -d -l /data/data/$APP &>/dev/null; then
	if ! $A shell ls -d -l /data/app/*/$APP* &>/dev/null; then
	    #echo "$APP not installed, trying to install it"
	    #(set -vx; $A unroot; $DRY $A install-multiple app/*/${APP}-*/*.apk; $A root )
	    (set -vx; $DRY $A install-multiple app/*/${APP}-*/*.apk )
	else
	    echo "$APP already installed, skipping install"
	fi
done

echo
echo "## Now installing app data"
echo "## Stop Runtime" && $DRY $A shell stop

for i in $APPS
do
	APP="$(basename $i)"
	echo "Attempting to restore data for $APP"
	# figure out current app user id
	L=( $($A shell ls -d -l /data/data/$APP 2>/dev/null) ) || :
	# drwx------ 10 u0_a240 u0_a240 4096 2017-12-10 13:45 .
	# => return u0_a240
	ID=${L[2]}

	if [[ -z $ID ]]; then
	    adb shell ls -d -l /data/data/$APP
	    echo "Error: $APP still not installed"
	    exit 2
	fi

	echo "APP User id is $ID"

	if ! $DRY $A shell "mkdir /data/data/$APP/.backup"; then
		echo "ERROR: Cannot create backup dir, skipping app data restore of $APP"
		continue
	fi
	echo "Backup $APP data to /data/data/$APP/.backup"
        $DRY $A shell "mv /data/data/$APP/{*,.backup}" || true
	if ! $DRY $A push "data/$APP" /data/data/; then
	    echo "Source data backup incomplete data/$APP missing in `pwd`"
	    exit
	fi

	# support directories like "Crash Reports"
	export IFS="
	"
	for j in `find data/$APP -printf "%P\n"`
	do
	    export IFS="$OLDIFS"
	    if [[ -d "data/$APP/$j" ]]; then
		echo "re-creating empty dir /data/data/$APP/$j"
		$DRY $A shell "mkdir -p \"/data/data/$APP/$j\""
	    fi
	    #echo "Fixing permissions on $j"
	    #test -z "$DRY" && echo $A shell chown $ID.$ID "/data/data/$APP/$j"
	    #$DRY $A shell chown $ID.$ID "\"/data/data/$APP/$j\""
	done
	export IFS="$OLDIFS"

	$DRY $A shell "set -vx; chown -R $ID.$ID /data/data/$APP/*" || true
	echo
done

echo "## Restart Runtime" && $DRY $A shell start
[[ -n $DRY ]] && echo "==== This is DRY MODE. Use --doit to actually copy."
echo "You will want to fix securelinux perms with: restorecon -FRDv /data/data"
