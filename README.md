# android-adb-backup
Backing up and restoring android apps via adb root (when you can't run TiBackup due to lack of SuperSU support)

This is not 'adb backup' which has 2 problems:
1) it skips backing up applications if they request not to be backed up.
That's a problem when it's your data and the application developer decides that 
you are now allowed to back it up or migrate it to a new device

2) adb backup has various bugs or issues depending on which version you use. 

This kind of does what TiBackup (from google play) does, but it's not nearly as smart.
However, it also just works on any device where you have adb root, whereas TiBackup 
requires SuperSU which is much harder to get working on some devices. 
As an example, google userdebug builds give you adb root, but will not give you any
way to run android apps as root, which TiBackup requires.

Intended usage:
1) run backup_apps.sh on the source device
2) manually look at which apps didn't get restored or have their data missing and run
restore_single_appdata.sh on them.
3) if the apk is missing, you can run adb install backup/dir/base.apk  with the destination
device

restore_apps.sh would restore all app data plus their apks, but it's probably not very
safe to use since not all apps ought to be restored/migrated that way (some have unique
IDs that end up causing problems if you use the same unique ID on different devices). 
I have left this script as a starter of something that almost works should you need such
a thing.

Credit goes to Raphael Moll for the original scripts.
