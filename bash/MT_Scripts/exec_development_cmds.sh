#!/bin/bash

# Name: exec_development_cmds.sh
# Environment: development
# Function: executes remote commands on the listed development servers
# Version: 09.03.13

# add target remote server names here
servers=( dev-app-001 dev-sql-001 )

# add remote commands to run here
commands=( "apt-get update" "apt-get upgrade" )

# add ssh login account 
ssh_user="opssuacct"

# add remote user to run command
remote_user="opsuser"

###########################
# Don't Modify Below Here #
###########################

# get remote server count
sc=${#servers[*]}

# get remote command count
cc=${#commands[*]}



dt=$(date +%Y_%m_%d_%H:%M:%S)
log_file="$dt.log"
log_path="/var/log/remote_exec/"
log=$log_path$log_file

if [ -d $log_path ]; then
        touch $log
        echo "Info - started log file $log" | tee >> $log
else
        echo "Error - Can't create $log_file in $log_path" 2>&1 | tee /tmp/remote_exec_fail.log
	exit 1
fi

# set server array index to 0
is=0
# set commands array index to 0
ic=0

while [ $is -lt $sc ]; do
	while [ $ic -lt $cc ]; do
		rc=0	
		start=(date +%H:%M:%S)
		echo "running command: on server: at $start using ssh user: $ssh_user and remote user: $remote_user" 2>&1 | tee >> $log 
		su -c "ssh $ssh_user@${servers[$is]} {commands[$ic]}" -s /bin/sh $remote_user || rc=$?
		if [ $rc -eq 0 ] ; then
			end=(date +%H:%M:%S)
       			echo "Info - command: {commands[$ic]} on server: {servers[$is]} using ssh user: $ssh_user and remote user: $remote_user completed at $end" 2>&1 | tee >> $log
		else
			end=(date +%H:%M:%S)
       			echo "Error - command: {commands[$ic]} on server: {servers[$is]} using ssh user: $ssh_user and remote user: $remote_user failed at $end" 2>&1 | tee >> $log
		fi
		ic=$[$ic + 1]
	done;
	# set remote_command[] index to 0
	ic=0
	is=$[$is + 1]
done;

dt=$(date +%Y_%m_%d_%H:%M:%S)
echo "finished running all commands at $dt" 2>&1 | tee >> $log
	
echo "complete command: on server: at $end 
