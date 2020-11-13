#!/bin/bash

# Name: list_backup_dir.sh
# Environment: all
# Function: displays the contents of /mnt/backups
# Version: 20130915

for day in `ls /mnt/backups` ; do  
	echo "";
	echo "---------------------------";
	echo "CURRENT BACKUP DAY IS: $day";
	echo "---------------------------------------";
	echo "CURRENT DIRECTORY IS: /mnt/backups/$day";
	echo "---------------------------------------";
	ls -lh "/mnt/backups/$day" | grep -v ^d | grep -v ^total | awk 'BEGIN { RS = "\t" } ; { print "file_name = " $9, "file_size = " $5, " date = " $6, $7 }';
	for dir in `ls -l /mnt/backups/$day | grep -i "^d" | awk '{ print $9 }'`; do
		file_chk=$(ls -l /mnt/backups/$day/$dir | grep -v ^d | grep -v ^total  | awk 'BEGIN { RS = "\t" } ; { print "file_name = " $9, "file_size = " $5, " date = " $6, $7 }';)
		if [ -n "$file_chk" ]; then
			echo "-----------------------------------------------";
			echo "CURRENT DIRECTORY IS: /mnt/backups/$day/$dir";
			echo "-----------------------------------------------";
			ls -lh /mnt/backups/$day/$dir | grep -v ^d | grep -v ^total  | awk 'BEGIN { RS = "\t" } ; { print "file_name = " $9, "file_size = " $5, " date = " $6, $7 }';
		fi
	done
done
