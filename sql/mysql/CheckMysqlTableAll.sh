#!/bin/bash

# Name: CheckMysqlTableAll.sh
# Environment: all
# Path: /mnt/automation/maintenance_scripts/
# Function: run mysqlcheck for all databases and all tables then email report
# Version: 20131004
# Dependency: none

##################################
## set email addresses to alert ##
##################################

notify_list="jquicke@opxdev.com"
dbuser="root"

###################################
## don't change below this point ##
###################################

# make sure only root can run script
if [ `whoami` != "root" ]; then
        echo "This script must be run as root"
        exit 1
fi

######################
## define variables ##
######################

script=$(basename "$0")
script_path=$(dirname "$0")
version=$(grep "# Version:" $script_path/$script | awk '{ print $3 }' | grep -v "Version:" )
host=$(hostname)
ymd=$(date +%Y%m%d)
est=$(date +%Y%m%d\ %H:%M)

log_path="/tmp/"
log="run_mysqlcheck_$ymd.log"

email_success="success...$script $host log for $est run"
email_failure="failure...$script $host log for $est run"

#####################
## set up functions ##
######################

get_interval(){
        local pit=$(date +%Y%m%d_%H:%M:%S)
        echo "$pit"
}

get_elapsed(){
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
	log_info "$script on $host ran in $elapsed_hours hours $elapsed_minutes minutes and $elapsed_seconds seconds"
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
	log_end "failure...exiting $script"
}

log_start(){
        local message="$1"
	local interval=$(get_interval)
        echo "START: | $message | $interval" >> $log_path$log
}

log_end(){
        local message="$1"
	get_elapsed
	local interval=$(get_interval)
        echo "END: | $message | $interval" >> $log_path$log
	if echo $message | grep -q "success" ; then
		log_send "$email_success"
		exit 0
	else
		log_send "$email_failure"
		exit 1
	fi
}

log_send(){
        local message="$1"
	if echo $message | grep -q "success" ; then 
		mail -s "$email_success" $notify_list < $log_path$log
	else
		mail -s "$email_failure" $notify_list < $log_path$log
	fi
}

############
## main() ##
############

start_seconds=$(date +%s)

interval=$(get_interval)
log_start "start $script (version: $version) on $host"

interval=$(get_interval)
log_info "begin check and analyze tables"

# mysqlcheck options: -C check only tables changed since last check | -A all databases | -a analyze (update statistics) | -o optimize (rebuild...slow) 
chk_string=$(mysqlcheck -A -a -u$dbuser | grep -v "OK" | grep -i -m1 -v "doesn't support analyze" | grep -i -m1 -v "already up to date")
if [ "$chk_string" != "" ]; then
        interval=$(get_interval)
        chk_string=$(echo $chk_string | tr '\n' ' ')
	log_warn "found problems with these tables: $chk_string"
        interval=$(get_interval)
	log_error "failed check and analyze tables"
else
        interval=$(get_interval)
        log_info "completed check and analyze tables"
fi

# mysqlcheck options: -C check only tables changed since last check | -A all databases | -a analyze (update statistics) | -o optimize (rebuild...slow) 
## uncomment the following lines only when you want to rebuild the table rather than sampling table data (it will lock tables for duration) 
#chk_string=$(mysqlcheck -A -o -u$dbuser | grep -v "OK" | grep -i -m1 -v "doesn't support analyze" | grep -i -m1 -v "already up to date")
#if [ "$chk_string" != "" ]; then
#	interval=$(get_interval)
#	chk_string=$(echo $chk_string | tr '\n' ' ')
#	log_warn "found problems with these tables: $chk_string"
#	interval=$(get_interval)
#	log_error "failed check and analyze tables"
#else
#        interval=$(get_interval)
#        log_info "completed check and analyze tables"
#fi

log_end "success...exiting $script"
