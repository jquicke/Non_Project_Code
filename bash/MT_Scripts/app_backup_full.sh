#!/bin/bash

# Name: app_backup_full.sh
# Environment: prod
# Function: creates a daily app server backup of /var/log and /var/www using tar, gzip, and scp
# Author: jquicke
# Version: 2013.09.26.1

# commented out debug switch
# set -x

##################################
## set email addresses to alert ##
##################################

notify_list="jquicke@opxdev.com"

###################################
## don't modify below this point ##
###################################

script=$(basename $0)
host=$(hostname)
storage_server="prd-utl-001"

ymd=$(date +%Y%m%d%H%M)
log="app_backup_$ymd.log"
log_path="/tmp/"
tmp_backup_path="/tmp/tmp_backup/"

dow=$(echo "day`date +%u`")
dow_path="/mnt/backups/$dow/"
var_www_path="/var/www/"
var_log_path="/var/log/"

www_backup="www_backup.tar"
log_backup="log_backup.tar"
backup="app_backup.tar.gz"

email_success="success...$script log for $host on $ymd"
email_failure="failure...$script log for $host on $ymd"

######################
## set up functions ## 
######################

get_interval(){ 
	local pit=$(echo `date +%Y%m%d_%H:%M:%S`)
	echo "$pit"
}

log_info(){ 
	local message="$1"
	echo "INFO: $message" >> $log_path$log
}

log_warn(){ 
	local message="$1"
	echo "WARN: $message" >> $log_path$log
} 

log_error(){
	local message="$1"
	echo "ERROR: $message" >> $log_path$log
}

send_log(){
        local subject="$1"
	local rs=""
        rs=$(echo $subject | grep -i "success")
        if [ "$rs" == "" ]; then
                mail -s "$email_failure" $notify_list < $log_path$log
                rm $log_path$log
                exit 1
	else
		mail -s "$email_success" $notify_list < $log_path$log
                rm $log_path$log
                exit 0
        fi
}

############
## main() ##
############

start_seconds=$(date +%s)
interval=$(get_interval)

log_info "start app backup $script for $dow at $interval"

# cleanup old backup temp directory if previous backup failed
if [ -d $tmp_backup_path ]; then
        rm -rf $tmp_backup_path
fi

if [ ! -d $dow_path ]; then
        log_error "failed check of $dow_path because does not exist or is not read/writable"
        log_error "exiting..." 
	send_log $email_failure
fi

log_info "using backup path $dow_path" 


interval=$(get_interval)
mkdir $tmp_backup_path
if [ $? -ne 0 ]; then
        log_error "failed to create $tmp_backup_path at $interval"
        log_error "exiting..."
        send_log $email_failure
else
        log_info "completed creation of $tmp_backup_path at $interval"
fi

interval=$(get_interval)
log_info "start backup for $var_www_path at $interval" 
tar -cvf $tmp_backup_path$www_backup $var_www_path* 
if [ $? -ne 0 ]; then
	interval=$(get_interval)
	log_error "failed tar and gzip of $var_www_path at $interval" 
	log_error "exiting..." 
	send_log $email_failure
else
	interval=$(get_interval)
	log_info "completed tar and gzip of $var_www_path at $interval"
fi

interval=$(get_interval)
log_info "start backup for $var_log_path at $interval" 
tar -cvf $tmp_backup_path$log_backup $var_log_path* 
if [ $? -ne 0 ]; then
	interval=$(get_interval)
	log_error "failed tar and gzip of $var_log_path at $interval" 
	log_error "exiting..." 
	send_log $email_failure
else
	interval=$(get_interval)
	log_info "completed tar and gzip of $var_log_path at $interval"
fi

interval=$(get_interval)
log_info "start tar and gzip of $tmp_backup_path to $dow_path at $interval" 
tar cvf - $tmp_backup_path* | gzip > $dow_path$backup
if [ $? -ne 0 ]; then
	interval=$(get_interval)
        log_error "failed tar or gzip of $tmp_backup_path to $dow_path at $interval" 
        log_error "exiting..." 
	send_log $email_failure
else
	interval=$(get_interval)
	log_info "completed tar and gzip of $tmp_backup_path to $dow_path at $interval" 
fi

interval=$(get_interval)
rm -rf $tmp_backup_path 
if [ $? -ne 0 ]; then
       	log_error "failed rm -rf of $tmp_backup_path at $interval" 
       	log_error "exiting..." 
	send_log $email_failure
else
	log_info "cleaned up $tmp_backup_path at $interval"
fi

interval=$(get_interval)
chown opsuser:opsuser $dow_path$backup
if [ $? -ne 0 ]; then
	log_error "failed change ownership of $dow_path$backup at $interval" 
        log_error "exiting..." 
	send_log $email_failure
fi

interval=$(get_interval)
log_info "start copy of $dow_path$backup to $storage_server at $interval" 
su -c "scp $dow_path$backup opsuser@$storage_server:$dow_path" -s /bin/sh opsuser
if [ $? -ne 0 ]; then
	interval=$(get_interval)
        log_error "failed copy of $dow_path$backup to $storage_server at $interval" 
        log_error "exiting..." 
	send_log $email_failure
else
	interval=$(get_interval)	
        log_info "completed copy of $dow_path$backup to $storage_server at $interval" 
fi

end_seconds=$(date +%s)
interval_seconds=$(($end_seconds - $start_seconds))
if [ $interval_seconds -ge 3600 ]; then
        elapsed_hours=$(($interval_seconds / 3600))
        hours_mod=$(($interval_seconds % 3600))
        if [ hours_mod = 1 ]; then
                elapsed_minutes=0
        else
                elapsed_minutes=$(($hours_mod / 60))
                elapsed_seconds=$(($interval_seconds % 60))
        fi
else
        if [ $interval_seconds -ge 60 ]; then
                elapsed_hours=0
                elapsed_minutes=$(($interval_seconds / 60))
                elapsed_seconds=$(($interval_seconds % 60))
        else
                elapsed_hours=0
                elapsed_minutes=0
                elapsed_seconds=$interval_seconds
        fi
fi

log_info "completed app backup in $elapsed_hours hours $elapsed_minutes minutes and $elapsed_seconds seconds" 
log_info "exiting..." 

send_log $email_success
