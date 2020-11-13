#!/bin/bash

# Name: BackupMysqlDbFull.sh
# Environment: dev
# Path: /mnt/automation/backup_recovery_scripts
# Function: creates a daily mysql backup uses the percona hotbackup tool and wrapper
# Version: 20131007
# Dependency: .my.pass 20131002

# commented out debug switch
# set -x

##################################
## set email addresses to alert ##
##################################

notify_list="jquicke@opxdev.com"

###################################
## don't modify below this point ##
###################################

# make sure only root can run script
if [ `whoami` != "root" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
fi

######################
## define variables ##
######################

script=$(basename $0)
script_path=$(dirname "$0")
version=$(grep "# Version:" $script_path/$script | awk '{ print $3 }' | grep -v "Version:" )
host=$(hostname)

prop_path="/mnt/automation/property_files/"
admin_user="dbadmin"
admin_pass=$(cat $prop_path.my_pass | grep -i "dbadmin" | awk '{ print $2 }')
db_instance=$(cat $prop_path.my_pass | grep -i "instance" | awk '{ print $2 }')

ymd=$(date +%Y%m%d%H%M)
emltmstmp=$(date +%Y%m%d\ %H:%M)
log_path="/tmp/"
log="mysql_backup_hot_$ymd.log"

dow=$(echo "day`date +%u`")
dow_path="/mnt/backups/$dow/"
hot_path=$(echo $dow_path"hot")
backup="hot.tar.gz"

email_success="success...$script $host log for $emltmstmp run"
email_failure="failure...$script $host log for $emltmstmp run"
email_unknown="unknown...$script $host log for $emltmstmp run"

script_start=$(date +%s)

######################
## set up functions ## 
######################

## timing functions

get_interval(){ 
	local pit=$(echo `date +%Y%m%d_%H:%M:%S`)
	echo "$pit"
}

get_elapsed(){
        local start_seconds="$1"
        local end_seconds=$(date +%s)
        local interval_seconds=$(($end_seconds - $start_seconds))
        if [ $interval_seconds -ge 3600 ]; then
                elapsed_hours=$(($interval_seconds / 3600))
                hours_mod=$(($interval_seconds % 3600))
                if [ $hours_mod = 1 ]; then
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
        log_info "elapsed time was $elapsed_hours hours $elapsed_minutes minutes and $elapsed_seconds seconds"
}

## logging functions

log_start(){
        local message="$1"
	local interval=$(get_interval)
        echo "START: | $message | $interval" >> $log_path$log
}

log_info(){ 
	local message="$1"
	local interval=$(get_interval)
	echo "INFO: | $message | $interval" >> $log_path$log
}

log_warn(){ 
	local message="$1"
	local interval=$(get_interval)
	echo "WARN: | $message | $interval" >> $log_path$log
} 

log_error(){
        local message="$1"
	local interval=$(get_interval)
        echo "ERROR: | $message | $interval" >> $log_path$log
        log_end "exiting $script with errors"
}

log_wtf(){
        local message="$1"
        local interval=$(get_interval)
        echo "WTF: | $message | $interval" >> $log_dir$log
}

log_end(){
        local message="$1"
        local send_chk=""
        local interval=$(get_interval)
        get_elapsed $script_start
        echo "END: | $message | $interval" >> $log_dir$log
        if echo $message | grep -i -q "success" ; then
                send_chk=$(log_send "$email_success")
                if [ $send_chk != "" ]; then
                        log_wtf "log_send() received error condition on mail command"
                fi
                exit
        else
                send_chk=$(log_send "$email_failure")
                if [ $send_chk != "" ]; then
                        log_wtf "log_send() received error condition on mail command"
                fi
                exit
        fi
}

log_send(){
        local message="$1"
        local mail_chk=""
        if echo $message | grep -i -q "success" ; then
                mail_chk=$(mail -s "$email_success" $notify_list < $log_dir$log)
        else
                if echo $email_subject | grep -i -q "errors" ; then
                        mail_chk=$(mail -s "$email_failure" $notify_list < $log_dir$log)
                else
                        mail_chk=$(mail -s "$email_unknown" $notify_list < $log_dir$log)
                fi
        fi
	echo "$mail_chk"
}

############
## main() ##
############

log_start "start $script (version:$version) on $host for $dow"

if [ ! -d $dow_path ]; then
        log_error "$dow_path does not exist"
fi

log_info "start cleanup of previous backup for $dow"

if [ -d $hot_path ]; then
        rm -r $hot_path
	log_warn "found $hot_path; last week's $dow backup might not have completed"
	log_info "cleaned up $hot_path; ready to start backup for $dow" 
fi

log_info "using backup path $dow_path" 

log_info "start base level backup for $dow" 
/usr/bin/innobackupex --user=$admin_user --password=$admin_pass --no-timestamp $hot_path
log_info "finish base level backup for $dow" 

log_info "start to apply transaction logs for $dow" 
/usr/bin/innobackupex --user=$admin_user --password=$admin_pass --apply-log --use-memory=1024MB $hot_path
log_info "finish application of transaction logs for $dow" 

log_info "completed full backup for $dow" 

log_info "start tar and gzip of $hot_path" 
tar cvf - $hot_path* | gzip > $dow_path$backup
if [ $? -ne 0 ]; then
	interval=$(get_interval)
        log_error "tar or gzip of $hot_path failed" 
else
	interval=$(get_interval)
	log_info "completed tar and gzip of $hot_path" 
fi

if [ -d $hot_path ]; then
	rm -rf $hot_path 2>1&
	if [ $? -ne 0 ]; then
        	log_error "rm -rf of $hot_path  failed" 
	else
		log_info "cleaned up $hot_path"
	fi
else
	log_warn "path $hot_path on $host was not deleted because it was not found"
fi

chown opsuser:opsuser $dow_path$backup
if [ $? -ne 0 ]; then
	log_error "change ownership of $dow_path$backup failed" 
fi

log_end "success...exiting $script!"
