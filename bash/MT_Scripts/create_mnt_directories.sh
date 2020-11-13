#!/bin/bash

# Name: create_mnt_directories.sh
# Function: creates automation and backup directory structure under /mnt
# Version: 08.20.13.0

# make sure only root can run script
if [ `whoami` != 'root' ]; then
        echo "This script must be run as root"
        exit 1
fi

path='/mnt/automation'

if [ ! -d $path ]; then
        mkdir -p $path
        echo 'created '$path
else
        echo $path' already exists; not creating it'
fi

for script_directory in backup_recovery_scripts user_scripts property_files maintenance_scripts setup_scripts libraries
do
        if [ ! -d $path/$script_directory ]; then
                mkdir -p $path/$script_directory
                echo 'created '$path/$script_directory
        else
                echo $path/$script_directory' already exists; not creating it'
        fi
done

path='/mnt/backups'

if [ ! -d $path ]; then
        mkdir -p $path
        echo 'created '$path
else
        echo $path' already exists; not creating it'
fi

backup_path='/mnt/backups/day'

for dow in `seq 1 7`
do
    if [ ! -d $backup_path$dow ]; then
        mkdir -p $backup_path$dow/cold
        mkdir -p $backup_path$dow/logs
        echo 'created '$backup_path$dow
    else
        echo $backup_path$dow ' already exists; not creating it'
    fi
done
