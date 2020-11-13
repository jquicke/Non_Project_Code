#!/bin/bash

# Name: get_server_stats.sh
# Description: gather memory, disk, and cpu information on servers without sar/sysstat
# Environment: all
# Path: /tmp/
# Dependencies: none
# Version: 20131009

##############################
## declare email recipients ##
##############################

email_recipients="james.quicke@gmail.com"

#######################
## declare variables ##
#######################

host=$(hostname)
script=$(basename "$0")
ymd=$(date +%Y%m%d)
log=$(echo $script | sed -e 's/\.sh/.log/')
path=/tmp/
err_cnt=0
command_list="free mount df"
file_list=("/etc/fstab" "/proc/cpuinfo" "/etc/hosts" "/etc/mysql/my.cnf")

#######################
## declare functions ##
#######################

checkLog(){
	echo "starting script $script on $host for $ymd"
	cat /dev/null > $path$log
	if [ $? -ne 0 ] ; then
        	echo"can't create log file $log in $path...exiting $script!"
	        exit 1
	else
        	echo "started script $script for $host on $ymd" >> $path$log
	        echo "created $log in $path" >> $path$log
	fi
}

addLine(){
	local line="$1"
	echo $line >> $path$log
}

checkAddLine(){
	addLine ""
	if [ $? -ne 0 ]; then
		echo "addLine() failed...exiting $script"
		exit 1
	fi
}

readFile(){
	local files="$1"
	for file in `echo "$files"`; do
		if [ -f $file ] ; then
			echo "reading $file:" >> $path$log
			cat $file >> $path$log
			addLine ""
		else
			echo "can't open $file for reading" >> $path$log
			addLine ""
			err_cnt=$(( $err_cnt + 1 ))
		fi
	done
}

getDistro(){
	echo "getting OS distribution:" >> $path$log
	if `ls /etc/*-release"`; then
        	readFile "/etc/*-release"
	        if [ $? -ne 0 ] ; then
        	        echo "readFile() for distro release file failed" >> $path$log
	        fi
	else
			echo "unknown distribution; check uname output for information" >> $path$log
			addLine ""
			err_cnt=$(( $err_cnt + 1 ))
	fi
    echo "running command: uname -a" >> $path$log
    uname -a >> $path$log
    if [ $? -ne 0 ]; then
		echo "uname command in runCommands() had errors" >> $path$log
		err_cnt=$(( $err_cnt + 1 ))
    fi
    addLine ""
}

runCommands(){
	local commands="$1"
	for command in `echo $commands` ; do
		echo "running command: $command" >> $path$log
	        $command >> $path$log
        	if [ $? -ne 0 ]; then
                	echo "error with command $command" >> $path$log
	                err_cnt=$(( $err_cnt + 1 ))
        	fi
	        addLine ""
	done
	echo "pausing for 10 seconds to run vmstat"
	echo "running command: vmstat 1 10" >> $path$log
	vmstat -n 1 10 >> $path$log
	if [ $? -ne 0 ]; then
		echo "vmstat command in runCommands() had errors" >> $path$log
		err_cnt=$(( $err_cnt + 1 ))
	fi
}
############
## main() ##
############
checkLog
if [ $? -ne 0 ] ; then
        echo "checkLog() failed...exiting $script"
        exit 1
fi

checkAddLine
if [ $? -ne 0 ] ; then
	echo "checkAddLine() failed...exiting $script"
	exit 1
fi

getDistro
if [ $? -ne 0 ] ; then
        echo "getLinuxDistro() call failed" >> $path$log
        err_cnt=$(( $err_cnt + 1 ))
fi

readFile "$file_list" 
if [ $? -ne 0 ] ; then
	echo "readFile() call failed"
	err_cnt=$(( $err_cnt + 1 ))
fi

runCommands "$command_list"
if [ $? -ne 0 ]; then
	echo "error with command $command" >> $path$log	
	err_cnt=$(( $err_cnt + 1 ))
fi

echo "finished script $script on $host for $ymd with $err_cnt errors" >> $path$log

mail -s "$script log from $host for $ymd" $email_recipient < $path$log
if [ $? -ne 0 ]; then
	echo "error sending script log to $email_recipient"
fi

echo "finished script $script on $host for $ymd"