#!/bin/bash
#*****************************************************
# SOURCE USER'S ENVIRONMENT VARIABLES
if [ -f /home/gpadmin/.bash_profile ];then
. /home/gpadmin/.bash_profile
export LANG=en_US.UTF-8
fi
#*****************************************************
# SETUP ENV
#*****************************************************
BASEDIR="/export/home/gpadmin/"
BNAME="`basename $0 | cut -f1 -d\.`"
TEA="/usr/bin/tee -a"
ECHO="/usr/bin/echo"
PSQL="/usr/local/greenplum-db/bin/psql"
DATE="/bin/date"
DATADIR=$BASEDIR/utilities
DATABASE="-d hw_edw"
PORT="-p 5432"
LOGDIR=$BASEDIR/utilities/log
LOGFILE=$LOGDIR/$BNAME.$$."`date '+%Y-%m-%d'`"
$ECHO "*********************************************************************"| $TEA $LOGFILE
$ECHO "********************SESSION KILLING SCRIPT***************************"| $TEA $LOGFILE
$ECHO "**********************************************************************"| $TEA $LOGFILE
while true
do
echo "Enter the process id that you want to Kill "
read pid
sid=`psql -At -c "select sess_id from pg_stat_activity where procpid=$pid;"`

i=1
while [ $i -le 10 ] 
do
m=`/usr/ucb/ps auxwww | grep $pid | grep -v "grep con$pid" | awk '{print $2}' | wc -l`
s1=`ssh sdw1 /usr/ucb/ps auxwww | grep con$sid | grep -v "grep con$sid" | awk '{print $2}' | wc -l`
s2=`ssh sdw2 /usr/ucb/ps auxwww | grep con$sid | grep -v "grep con$sid" | awk '{print $2}' | wc -l`
if [ $s1 -gt 0 ] or [ $s2 -gt 0 ] or [ $m -gt 0 ]
then
/usr/ucb/ps auxwww | grep con$pid | grep -v "grep con$pid" | awk '{print $2}' | xargs kill 2>/dev/null
ssh sdw1 /usr/ucb/ps auxwww | grep con$sid | grep -v "grep con$sid" | awk '{print $2}' | xargs ssh sdw1 kill 2>/dev/null
ssh sdw2 /usr/ucb/ps auxwww | grep con$sid | grep -v "grep con$sid" | awk '{print $2}' | xargs ssh sdw2 kill 2>/dev/null
if [ $i -eq 10 ]; then
echo "The segment process are still not being killed please try running the script after sometime......"
exit
fi
else
echo "No process running on mdw or sdw1 or sdw2......"
echo "script exiting....."
sleep 5
exit
fi
i=`expr $i + 1`
done