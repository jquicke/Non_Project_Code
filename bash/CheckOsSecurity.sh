#!/bin/bash

# Name: CheckOsSecurity.sh
# Function: run chkrootkit, rkhunter utilities and mail results
# Version: 08.08.13.0

notify_list='jquicke@opxdev.com'
host='hostname'
log_path='/tmp/'
log_time=$(date +%s)
log_name='security_check.'
log=$log_path$log_name$log_time
touch $log
email_subject='run_security_check.sh for '$host' on '
chkrootkit='/usr/sbin/chkrootkit'
rkhunter='/usr/bin/rkhunter'

# make sure only root can run script
if [ `whoami` != 'root' ]; then
        echo "This script must be run as root" > $log
        mail -s "$email_subject" $notify_list < $log
        exit 1
fi

# check chkrootkit is installed and executable
if [ ! -x $chkrootkit ]; then
        echo "chkrootkit is not installed or not executable" > $log
        mail -s "$email_subject" $notify_list < $log
        exit 1
fi

$chkrootkit -q 2>&1 | grep -v "/usr/lib/pymodules/python2.7/.path" | tee -a $log

# check rkhunter is installed and executable
if [ ! -x $rkhunter ]; then
        echo "rkhunter is not installed or not executable" > $log
        mail -s "$email_subject" $notify_list < $log
        exit 1
fi

(
  $rkhunter --update 2>&1
  $rkhunter --propupd
  $rkhunter --cronjob --report-warnings-only 2>&1
) | tee -a $log

mail -s "$email_subject" $notify_list < $log

