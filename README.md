# android-adb-backup
Backing up and restoring android apps via adb root (when you can't run
TiBackup due to lack of SuperSU support)

adb backup used to do almost the same thing, but it's dead now.
bmgr restore also isn't supported anymore.

These scripts kind of does what TiBackup (from google play) does, but
they're not nearly as smart.
However, they will work on any device where you have adb root, whereas
TiBackup requires SuperSU which is much harder to get working on some
devices.
As an example, google userdebug builds give you adb root, but will not
give you any way to run android apps as root, which TiBackup requires.

Intended usage:
1) run backup_apps.sh on the source device, consider moving out any
   app called com.android/com.google as they usually have good enough
   built in backups and copying their data on another device may create
   duplicate IDs and problems later 
2) Actually in newer androids, I've found that adb pull /data/data and 
   adb pull /data/app is easier
3) then run restore_apps.sh against the destination device. You can
   optionally give one or more package names if you don't want to
   restore all packages

Keep in mind that even with step #3, restoring all apps may cause issues
as some have unique IDs that end up causing problems if you use the same
unique ID on different devices.
You may want to consider only restoring apps that are missing from google play or apps
that sadly decide to prevent backups of their (i.e. your) data.

Credit goes to Raphael Moll for the original idea/scripts this was based on.
