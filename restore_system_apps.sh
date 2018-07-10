#!/bin/bash

# License; Apache-2

# Tested/Fixed for Android O by marc_soft@merlins.org 2017/12

set -e   # fail early

cat <<EOF
WARNING: restoring random system apps can make things worse
You may want to prune the list of apps to restore
^C to exit, ENTER to continue
EOF
read

A="adb -d"
OLDIFS="$IFS"

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
echo "## Stop Runtime" && $DRY $A shell stop

for i in $APPS
do
	APP="$(basename $i)"
	echo "Attempting to restore data for $APP"
	# figure out current app user id
	if ! L=( $($A shell ls -d -l /data/data/$APP) ); then
		echo "ERROR: cannot restore $APP, not installed on device"
	else
		# drwx------ 10 u0_a240 u0_a240 4096 2017-12-10 13:45 .
		# => return u0_a240
		ID=${L[2]}
                echo "User id => $ID"
                
                if ! $A shell "mkdir /data/data/$APP/.backup"; then
			echo "ERROR: Cannot create backup dir, skipping app $APP"
			continue
		fi
		echo "Backup $APP data to /data/data/$APP/.backup"
                $DRY $A shell "mv /data/data/$APP/{*,.backup}"
                $DRY $A push data/$APP /data/data/

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
	fi
done

echo "## Restart Runtime" && $DRY $A shell start
[[ -n $DRY ]] && echo "==== This is DRY MODE. Use --doit to actually copy."
echo "You will want to fix securelinux perms with: restorecon -FRDv /data/data"
