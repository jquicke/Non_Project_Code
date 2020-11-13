#!/bin/bash
conn=0
TIME=2700
HELP=0
################################################################################################
# Objective  : To identify the CONNECTIONS  IDLE for more than 45 minutes

# Summary    : This will identify the pid's and will issues a kill for then:
# Logging    : All logs will be stored in $HOME/gpAdminLogs/gp_idle.log 
# Consequences    : Connections killed will get the below error messages and they would need to reconnect 
#            FATAL:  terminating connection due to administrator command
#            server closed the connection unexpectedly
#                This probably means the server terminated abnormally
#                before or while processing the request.
#            The connection to the server was lost. Attempting reset: Succeeded. 
################################################################################################

help() {
echo '
    -h    : Display help
    -c    : kill idle connections
    -t    : age of query and connection [default: 2700 seconds ]
    idleconn.sh -c  -t 3000 [default: 2700 values in seconds]
    idleconn.sh -c            [default: 2700 values in seconds]
'
}
source $GPHOME/greenplum_path.sh


loging (){
# Logging all the connections which were idle for more than 2700s 
psql -t -c "select * from pg_stat_activity where now()-backend_start > '${TIME}s'" template1 >> $HOME/gpAdminLogs/gp_idle.log
}


idle_conn () {
# Generating pid's for connections opened for more then 45 minutes :

psql -A -t -c "SELECT 'kill '||procpid from pg_stat_activity where now()-backend_start > '${TIME}s' or current_query ='<IDLE>' " template1 | bash
 }

if [ $# -ne 0 ];then
        while getopts "ct:h" opts;do
                case  "$opts" in

        c)
        conn=1
        ;;
        t)
        TIME=$OPTARG;
        ;;
        h)
        HELP=1
        ;;
        esac
    done
#else
#help
fi

date >> $HOME/gpAdminLogs/gp_idle.log
if [ $HELP -eq 1 ] || [ $conn -eq 0 ];then
help
fi


if [ $conn -eq 1 ];then
loging
idle_conn
fi
date >> $HOME/gpAdminLogs/gp_idle.log