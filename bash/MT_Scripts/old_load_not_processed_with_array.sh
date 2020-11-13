#!/bin/bash

# Name: old_load_not_processed_with_array.sh
# Function: main() code for daily sftp data loads
# Version: 20130823
# Dependency: load_library

# make sure only root can run script
if [ `whoami` != "root" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
fi

users=( mcdonaldftp pfguser shetakisuser pfgphilly )

lib_path='/mnt/automation/libraries'
load_lib='sftp_load_library'
processed_path='/mnt/customer_data/processed'
not_processed_path='/mnt/customer_data/not_processed'

if [ -f "$lib_path/$load_lib" ]; then
        . $lib_path/$load_lib
else
        echo "Error:    Library file $lib_path/$load_lib does not exist or does not have read/write permissions" 1>&2
        exit 1
fi

# count users in array
user_count=${#users[*]}

# set error checking flag and array index
error=0
index=0

while [ $index -lt $user_count ]; do
        if [ ! -d $not_processed_path/${users[$index]}/uploads ]; then
                sftp_log_warn "$not_processed_path/${users[$index]}/uploads does not exist or does not read/write permissions"
                error=1
        fi
        if [ ! -d "$processed_path/${users[$index]}/data" ]; then
                sftp_log_warn "$processed_path/${users[$index]}/data does not exist or does not have read/write permissions"
                error=1
        fi
        if [ ! -d "$processed_path/${users[$index]}/logs" ]; then
                sftp_log_warn "$processed_path/${users[$index]}/log does not exist or does not have read/write permissions"
                error=1
        fi
        index=$[$index + 1]
done

# now we have logged all the path/directory problems that need fixing, bail out of the script with failure exit code
if [ $error -gt 0 ]; then
        sftp_log_error "Exiting load_sftp_data_daily.sh!"
        exit 1
fi

# reset the array index
index=0

while [ $index -lt $user_count ]; do
        sftp_log_note "the user: ${users[$index]} is gonna be processed...whoot!"
        index=$[$index + 1]
done
