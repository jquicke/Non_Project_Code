#!/bin/bash

create_list() {
        CONN=`psql -Atc "select ' '  || array_to_string(array(select 'con' || sess_id from pg_stat_activity), ' | ') || ' ';" template1`

        procs=`gpssh -f all_hosts_file /usr/ucb/ps axw | grep postgres | grep ' con' | egrep -v "($CONN)"|awk '{print $2}'`

	# echo $CONN

        echo $procs
}

LIST1=`create_list`
echo $LIST1
sleep 60
LIST2=`create_list`
echo $LIST2

if [ "$LIST1" == "$LIST2" ] && [ x"$LIST1" != x"" ];then
        echo "These processes must be killed: $LIST1"
else
        echo "No orphaned processes were found."
fi
