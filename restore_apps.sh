#!/bin/bash

# License; Apache-2

# Originally from Raphael Moll
# Untested as of 2017/12, but should probably work as is or with little modification
# USE AT YOUR OWN RISK
# For a safer per package restore, try restore_single_appdata.sh

set -e   # fail early

A=adb

DRY="echo"
OP=""

DIR="$1"
shift
if [[ ! -d "$DIR" ]]; then
	echo "Usage: $0 <date-dir> [-f] [--apk|--data]"
	echo "Must be created with ./backup_apps.sh"
    echo "-apk: install apk only, not data"
	exit 2
fi

if [[ "$1" == "-f" ]]; then DRY=""; shift; fi
if [[ "$1" == "--apk" || "$1" == "--data" ]]; then OP="$1"; shift; fi


cd $DIR

echo "## Restart adb as root"
$A root
sleep 3

echo "## Push apps"

for i in app/*.apk ; do
    if [[ -e $i ]]; then
        apk=${i/app\//}
        
        # name of apk is <packagename>-<number.apk
        name=${apk/.apk/}
        name=${name%%-[0-9]*}
	# /data/app/org.openintents.filemanager-0lGhieUsRc8H0LTGv2DyYQ==
	# ccc71.at.free-cEQUrmG-8tLASwXXJi-03Q==
	name=${name%%-*==}
        
        echo $name
        
        if [[ -z "$OP" || "$OP" == "--apk" ]]; then
            echo "## install $name"
            $DRY $A install -r app/$apk
        fi
        
        if [[ -z "$OP" || "$OP" == "--data" ]]; then
            if [[ -d data/$name ]]; then
            
                # figure out current app user id
                L=`$A shell ls -l /data/data | grep $name`
                ID=`echo $L | cut -f 2 -d " "`
                echo "User id => $ID"
                
                $DRY $A push data/$name /data/data/$name
                for j in `find data/$name -printf "%P\n"`; do
                    if [[ -e "data/$name/$j" ]]; then
                        $DRY $A shell chown $ID.$ID /data/data/$name/$j
                    fi
                done
            else
                echo "  Missing data/$name"
            fi
        fi
    fi
done

[[ -n $DRY ]] && echo "==== This is DRY MODE. Use -f to actually copy."
