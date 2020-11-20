#!/bin/bash
 
# Set Variables Here
vmstat_frequency=1
vmstat_duration=10
timestamp=$(date +%s)
vmstat_filename="vmstat_output_"$timestamp".txt"
postgres_filename="pglog_output_"$timestamp".txt"
log_marker="TEST_MARKER."$timestamp
test_path="/mount/postgres/archive_log/stress_test/load_data/"
log_path="/var/lib/postgresql/9.2/main/pg_log/"
log_name="postgres.log"
 
# Code Starts Here
cd $test_path
echo $log_marker >> $log_path$log_name
timeout $vmstat_duration vmstat -n $vmstat_frequency > $vmstat_filename
cp $log_path$log_name $postgres_filename
awk "/$log_marker/,0" $postgres_filename > $postgres_filename.$$
mv $postgres_filename.$$ $postgres_filename
awk '{print $7 "\t" $8 "\t" $9 "\t" $10 "\t" $13 "\t" $14 "\t" $15 "\t" $16}' $vmstat_filename > $vmstat_filename.$$
sed -i '1,3d' $vmstat_filename.$$
sed -i '/^$/d' $vmstat_filename.$$
sed -i "1iswp_in\tswp_out\tio_in\tio_out\tuser\tsystem\tidle\twait" $vmstat_filename.$$
mv $vmstat_filename.$$ $vmstat_filename