#!/bin/bash

# License; Apache-2

# Tested/Fixed for Android O by marc_soft@merlins.org 2017/12
# Added support for filenames/directories with spaces


set -e   # fail early

A="adb -d"

DRY="echo"
if [[ "$1" == "--doit" ]]; then DRY=""; shift; fi
DIR="$1"
shift

if [[ ! -d "$DIR" ]]; then
	echo "Usage: $0 [--doit] <date-dir>"
	echo "Must be created with ./backup_system_apps.sh"
	echo "Will be dry run by default unless --doit is given"
	exit 2
fi

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

echo "## Install missing apps"
for i in $APPS
do
	APP="$(basename $i)"
	if ! $A shell ls -d -l /data/data/$APP &>/dev/null; then
		echo "$APP not installed, trying to install it"
		(set -vx; $DRY $A install app/${APP}*/base.apk )
	fi
done

echo "## Stop Runtime" && $DRY $A shell stop

for i in $APPS
do
	APP="$(basename $i)"
	# figure out current app user id
	L=( $($A shell ls -d -l /data/data/$APP 2>/dev/null) ) || :
	# drwx------ 10 u0_a240 u0_a240 4096 2017-12-10 13:45 .
	# => return u0_a240
	ID=${L[2]}

	if [[ -z $ID ]]; then
	    echo "Error: $APP still not installed"
	    $DRY exit 2
	fi

	echo "APP User id is $ID"

	if ! $DRY $A shell "mkdir /data/data/$APP/.backup"; then
		echo "ERROR: Cannot create backup dir, skipping app $APP"
		continue
	fi
	echo "Backup $name data to /data/data/$APP/.backup"
        $DRY $A shell "mv /data/data/$APP/{*,.backup}"
	$DRY $A push "data/$APP" /data/data/

	(cd "data/$APP"
	# support directories like "Crash Reports"
	export IFS="
	"
	for j in `find . -printf "%P\n"`; 
	do
	    if [[ -d "$DIR/$j" ]]; then
		$DRY $A shell "mkdir -p \"/data/data/$APP/$j\""
	    fi
	    #echo "Fixing permissions on $j"
	    #test -z "$DRY" && echo $A shell chown $ID.$ID "/data/data/$APP/$j"
	    #$DRY $A shell chown $ID.$ID "\"/data/data/$APP/$j\""
	done )

	$DRY $A shell "set -vx; chown -R $ID.$ID /data/data/$APP/*" || true
	echo
done

echo "## Restart Runtime" && $DRY $A shell start
[[ -n $DRY ]] && echo "==== This is DRY MODE. Use --doit to actually copy."

