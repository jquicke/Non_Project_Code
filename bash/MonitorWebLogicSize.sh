#!/usr/bin/ksh
# Purpose: Monitors the weblogic log size increasing to check the weblogic 
server is not hung
# set the hostname, directory location, and logfile name
WEBLOGIC_MONITOR_HOSTNAME="devjpy01"
WEBLOGIC_LOG="test_logic.log"
WEBLOGIC_LOG_HOME="/tmp/jmq/monitor"
# set the email list of people to notify
# note: leave a space before and after each email address
EMAIL_LIST=" james.quicke@t-mobile.com "
# set the time interval in seconds to check the log
# i.e set CHECK_INTERVAL="300" for a check every 5 minutes
CHECK_INTERVAL="10"
#############################################
##  DO NOT MODIFY SCRIPT BELOW THIS POINT  ##
#############################################
export WEBLOGIC_MONITOR_HOSTNAME
export WEBLOGIC_LOG
export WEBLOGIC_LOG_HOME
export EMAIL_LIST
export CHECK_INTERVAL
# check log is there and readable
if [ ! -f "$WEBLOGIC_LOG_HOME/$WEBLOGIC_LOG" ]; then
	echo "Error: could not read $WEBLOGIC_LOG at $WEBLOGIC_LOG_HOME"
	echo "Bailing out of $0"
	exit 1
fi
# declare size and alert functions
GetSize() {
	sleep $CHECK_INTERVAL
	unset NEW_SIZE
	NEW_SIZE=`ls -l "$WEBLOGIC_LOG_HOME/$WEBLOGIC_LOG" | awk ' {print $5} '`
	export NEW_SIZE
}
RaiseAlert() {
	mailx -s "$WEBLOGIC_LOG on $WEBLOGIC_MONITOR_HOSTNAME has not been written 
in $CHECK_INTERVAL seconds " $EMAIL_LIST << EOF
WARNING: $WEBLOGIC_LOG on $WEBLOGIC_MONITOR_HOSTNAME was $LAST_SIZE bytes 
$CHECK_INTERVAL seconds ago and still $NEW_SIZE bytes now!!!
EOF
}
# get initial size of log file
GetSize
LAST_SIZE=$NEW_SIZE
# start loop and monitor log
while :
do
	GetSize
	if [ "$NEW_SIZE" = "$LAST_SIZE" ]; then
		RaiseAlert
	fi
	LAST_SIZE=$NEW_SIZE
done