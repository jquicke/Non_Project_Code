#!/bin/bash

# Name: process_pfg_data.sh
# Environment: all
# Function: process and load a single day of pfg data
# Version: 20130925
# Dependency: .my.pass 20130923

# commented out debug switch
# set -x

##################################
## set email addresses to alert ##
##################################

notify_list="jquicke@opxdev.com"

###################################
## don't modify below this point ##
###################################

script=$(basename $0)
host=$(hostname)
sftpuser="pfguser"

admin_user="dbadmin"
load_user="dataloader"
mt_user="mtadmin"
admin_pass=$(cat /root/.my.pass | grep -i "dbadmin" | awk '{ print $2 }')
load_pass=$(cat /root/.my.pass | grep -i "dataloader" | awk '{ print $2 }')
mt_pass=$(cat /root/.my.pass | grep -i "mtadmin" | awk '{ print $2 }')
db_instance=$(cat /root/.my.pass | grep -i "instance" | awk '{ print $2 }')

uploads_dir="/mnt/customer_data/not_processed/$sftpuser/uploads/"
split_dir="/mnt/customer_data/being_processed/$sftpuser/split/"
wait_dir="/mnt/customer_data/being_processed/$sftpuser/waiting/"
done_dir="/mnt/customer_data/processed/$sftpuser/"
log_dir="/var/log/dataload/"
paths="$uploads_dir $split_dir $wait_dir $done_dir"

ymd=$(date +%Y%m%d%H%M%S)
log=$(echo "process_$sftpuser_log.$ymd")

email_success="success...$script log for $host on $ymd"
email_failure="failure...$script log for $host on $ymd"

script_start_time=$(date +%s)

######################
## define functions ##
######################

# time functions

get_interval(){
        local pit=$(echo "`date +%Y%m%d:%H:%M:%S`")
        echo "$pit"
}

get_elapsed(){
        local start_seconds="$1"
        local end_seconds=$(date +%s)
        local interval_seconds=$(($end_seconds - $start_seconds))
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
        log_info "elapsed time was $elapsed_hours hours $elapsed_minutes minutes and $elapsed_seconds seconds"
}

# logging functions

log_start(){
        rtrn_val=0
	local message="$1"
	local interval=$(get_interval)
        echo "$interval	START:	$message" >> $log_dir$log
	if [ $? -ne 0 ]; then
		rtrn_val=1
	else
		log_info "logging started without errors"
	fi
	echo "rtrn_val"
}

log_info(){
        local message="$1"
	local interval=$(get_interval)
        echo "$interval	INFO:	$message" >> $log_dir$log
}

log_warn(){
        local message="$1"
	local interval=$(get_interval)
        echo "$interval	WARN:	$message" >> $log_dir$log
}

log_error(){
        local message="$1"
	local interval=$(get_interval)
        echo "$interval	ERROR:	$message" >> $log_dir$log
	log_end $email_failure
}

log_wtf(){
        local message="$1"
        local interval=$(get_interval)
        echo "$interval WTF:  $message" >> $log_dir$log
        echo "$interval WTF:  Exiting with dirty log_end()" >> $log_dir$log
	exit 1
}

log_email(){
        local rtrn_val=0
	local email_subject="$1"
	local mail_chk=""
        if echo $email_subject | grep -i -q "success..." ; then
                mail_chk=$(mail -s "$email_subject" $notify_list < $log_dir$log)
        	if [ "$mail_chk" != "" ]; then 
			rtrn_val=1
		fi
	else
		if echo $email_subject | grep -i -q "failure..." ; then
	                mail_chk=$(mail -s "$email_subject" $notify_list < $log_dir$log)
        		if [ "$mail_chk" != "" ]; then 
				rtrn_val=1
			fi
	        else
			mail_chk=$(mail -s "$email_subject" $notify_list < $log_dir$log)
                        if [ "$mail_chk" != "" ]; then
                                rtrn_val=1
                        fi
		fi
	fi
	echo "$rtrn_val"
}

log_end(){
        local message="$1"
	local interval=$(get_interval)
	get_elapsed $script_start_time
        echo "$interval	END:    $message" >> $log_dir$log
        log_email $message
	if [ $? -ne 0 ]; then
		log_wtf="log_email() called in log_end() with a non null return code"
	fi
	if echo $message | grep -i -q "success..." ; then
		exit 0
	else
		exit 1
	fi
}

# validation functions

test_log(){
	if [ ! -d $log_dir ]; then
        	echo "ERROR: log directory $log_dir does not exist or does not have read/write permissions"
		echo "Exiting $script!!!"
		exit 1
	fi
}

test_dir(){
        local test_dir=$1
        if [ ! -d $test_dir ]; then
		log_error "test_dir() failed for directory $test_dir"
        fi
}

test_paths(){
	local dir=""
	for dir in `echo $paths`; do
        	test_dir $dir
		if [ $? -ne 0 ]; then
			log_error "test_paths() failed at test_dir() for dir $dir"
		else
        		log_info "path $dir exists and has read/write"
		fi
        done
}

# utility functions

count_files(){
        local rtrn_cnt=0
        local cmp_dir=$1
        local cmp_file=$2
	test_dir $cmp_dir
        if [ ! -n $cmp_file ]; then
                rtrn_cnt=$(ls -l $cmp_dir | grep -v -i "^total" | awk '{ print $9 }' | wc -l)
                if [ $? -ne 0 ]; then
                        echo "count_files() failed for directory $cmp_dir"
                fi
        else
                rtrn_cnt=$(ls -l $cmp_dir | grep -v -i "^total" | grep -i "$cmp_file" | awk '{ print $9 }' | wc -l)
                if [ $? -ne 0 ]; then
                        echo "count_files() failed for file $cmp_file and directory $cmp_dir"
                fi
        fi
        echo -n "$rtrn_cnt"
}

cleanup_files(){
        local rtrn_val=1
	local cln_dir=$1
	local cln_files=$2
        local warn_val=0
	test_dir $cln_dir
	if [ $? -ne 0 ]; then
		log_error "test_dir() inside of cleanup_files() failed"
	fi
	if [ ! -n "$cln_files" ]; then
		rm -f $cln_dir
		if [ $? -ne 0 ]; then
                        log_warn "cleanup_files() failed for directory $cln_dir"
			warn_val=1
                fi
	else
		for file in `ls $cln_files`; do
			rm -f $cln_dir$file
			if [ $? -ne 0 ]; then
                	        log_warn "cleanup_files() failed for file $file in directory $cln_dir"
				warn_val=1
			else
				log_info "removed file $file from directory $cln_dir"	
			fi
		done
	fi		
	if [ $warn_val -ne 0 ]; then
		log_error "errors with cleanup_files() for $cln_dir and $cln_files"
	else
		rtrn_val=$warn_val
	fi
	echo "$rtrn_val"
}

check_zip(){
	local rtrn_val=1
	local zip_dir=$1
	local zip_file=$2
	local zip_chk=""
	test_dir $zip_dir
	zip_chk=$(file $zip_dir$zip_file | grep -v -i "Zip archive data")
	if [ $? -ne 0 ]; then
        	log_error "failure of file utility in check_zip() (directory = $zip_dir) (file = $zip_file)"
	else
        	if [ "$zip_chk" != "" ]; then
                	log_error "$zip_file in $zip_dir is not a zip file"
	        else
        	        log_info "$zip_file in $zip_dir is a zip file"
			rtrn_val=0
		fi        
	fi
	echo "$rtrn_val"
}

unzip_file(){
	local zip_dir=$1
	local zip_file=$2
	local zip_chk=1
	zip_chk=$(check_zip $zip_dir $zip_file)
	if [ $zip_chk -ne 0 ]; then
		log_error "failure of check_zip() (directory = $zip_dir) (file = $zip_file)"
	fi
	which unzip 1>/dev/null
	if [ $? -ne 0 ]; then
		log_error "failure of /usr/bin/which for unzip utility in unzip_file()"
	else
		unzip $zip_dir$zip_file
		if [ $? = 0 ]; then
			log_error "unzip of $zip_file in $zip_dir failed"
		else
			log_info "unzip of $zip_file  in $zip_dir completed"
		fi
	fi
}

# database functions

db_conn(){
	local rtrn_val=1
	local stmt="$1"
        local rs=$(mysql -u$load_user -p$load_pass -h$db_instance -e"$stmt")
        if [ $? -ne 0 ]; then
                log_error "db conn() for $stmt failed"
        else
                rtrn_val=$rs
        fi
        echo "$rtrn_val"        
}

test_db_conn(){
	local rtrn_val=1
	local rs=""
	local test_stmt="select test from loadlogs.test_conn;" 
	rs=$(db_conn "$test_stmt")
	if [ $? -ne 0 ]; then
        	log_error "db_conn() method failed to make a initial connection inside test_db_conn()"
	else
        	rs=$(echo $rs | grep -i "okay")
	        if [ $? -ne 0 ]; then
        	        log_error "test_db_conn() errored on grep of result set"
        	else
                	if [ -n $rs ]; then
        	        	log_error "test_db_conn() failed on $stmt"
			else
				log_info "test_db_conn() passed with $conn"
				rtrn_val=0
        		fi
		fi
	fi
	echo "$rtrn_val"
}

############
## main() ##
############

# test logging 
test_log
if [ $? -ne 0 ]; then
	echo "ERROR: problem with executing test_log function"
	echo "Exiting $script!!!"
	exit 1
fi

# start logging
log_start "starting up logging for $script"
if [ $? -ne 0 ]; then
        log_error "error with function log_start()"
fi

# test file paths
test_paths
if [ $? -ne 0 ]; then
        log_error echo "function test_paths() failed"
else
        log_info " all file path tests passed"
fi

# test db connection
rs=$(test_db_conn)
if [ $? -ne 0 ]; then 
	log_error "db_conn() method failed to make a initial connection" 
else 
	echo $rs | grep -i "okay" 
	if [ $? -ne 0 ]; then
		log_error "db connection test failed on $conn"
	else 
		log_info "db connection test passed with $conn"
	fi
fi

# check sftp dir for single file
file_chk=$(count_files $uploads_dir)
if [ $? -ne 0 ]; then 
	log_error "count_files() check for single file in $uploads_dir failed"
else
	if [ $file_chk -ne 1 ]; then
		if [ $file_chk -gt 1 ]; then
			log_error "there are more than 1 files in $uploads_dir (file_count = $file_chk)"
		else
			log_error "there aren't any files in $uploads_dir (file_count = $file_chk)"
		fi
	else
		log_info "there are the correct number of files in $uploads_dir (file_count = $file_chk)"
	fi
fi

# get the name of uploaded file
upload_file=$(ls $uploads_dir)
if [ $? -ne 0 ]; then 
	log_error "unable to assign upload_file variable for the file in $uploads_dir"
else
	log_info "got name for uploaded file in $uploads_dir (file_name = $upload_file)"
fi

# remove all files from split dir
cleanup_files $split_dir
if [ $? -ne 0 ]; then
        log_error "failed to clean up $split_dir"
else
	log_info "cleaned up $split_dir and now ready to copy of $upload_file"

fi	

# copy uploaded file to waiting directory to save it, copy uploaded file to split directory for processing
for dir in $wait_dir $split_dir; do 
	cp $uploads_dir$upload_file $dir
	if [ $? -ne 0 ]; then
		log_error "failed to copy of $upload_file from $uploads_dir to $dir"
	else
		log_info "copied $upload_file from $uploads_dir to $dir"
	fi
done

# remove uploaded file from sftp uploads dir
cleanup_files $uploads_dir $upload_file
if [ $? -ne 0 ]; then
        log_error "error with cleanup_files() for $upload_file from $uploads_dir"
else
        log_info "cleaned up $upload_file from $uploads_dir"

fi

# unzip uploaded file in split dir
unzip_file $split_dir $upload_file
if [ $? -ne 0 ]; then
        log_error "unzip_file of $upload_file in $split_dir failed"
fi

# count the unzipped files
file_cnt=$(file_count $split_dir)
if [ $? -ne 0 ]; then
	log_error "error with file_count() getting a count of files in $split_dir"
else
	if [ $file_cnt -ne 2 ]; then
		log_error "unzip of $upload_file in $split_dir more than 2 files (file count = $file_cnt)"
	else
		log_info "there are the correct number of unzipped files in $split_dir (file count = $file_cnt)"
	fi
fi

# find the data file, grab the first column of the header row, and validate it
data_file=$(ls $split_dirMLTKTDAT*)
if [ $? -ne 0 ]; then
	log_error "error looking for data file in $split_dir"
else
	header_chk=$(head -1 $data_file | awk 'BEGIN {FS=","} { print $1 }')
	if [ $? -ne 0 ]; then
        	log_error "error with awk during header_chk variable creation"
	else
		if [ "$header_chk" != "DISTRIBUTOR_NUMBER" ]; then
        		log_error "header DISTRIBUTOR_NUMBER != $header_chk"
		else
		        log_info "header DISTRIBUTOR_NUMBER = $header_chk"
		fi
	fi
fi

# find the control file, sanitize that nasty thing, and get a row count
cntrl_file=$(ls $split_dirMLTKTCTL*)
if [ $? -ne 0 ]; then
        log_error "error looking for control file in $split_dir"
else
	dos2unix $cntrl_file 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		log_error "problem with dos2unix of control file $cntrl_file in $split_dir"
	else
		cntrl_cnt=$(head -1 $cntrl_file | awk 'BEGIN {FS=","} { print $3 }')
		if [ $? -ne 0 ]; then
		        log_error "problem with awk of cntrl_cnt variable creation"
		fi
	fi
fi

# count the data file row count, subtract 1 row in awk to allow for header row that will be stripped, compare results
header_cnt=$(wc -l $data_file | awk '{ print $1-1 }')
if [ $? -ne 0 ]; then
        log_error "problem with awk in header_cnt variable creation"
else
	if [ $header_cnt -ne $cntrl_cnt ]; then
        	log_error "data file and control file row counts do not match: $header_cnt != $cntrl_cnt"
	else
        	log_info "data file and control file row counts match: $header_cnt != $cntrl_cnt"
	fi
fi

# strip the header from the data file, get row counts, compare results
sed -i -e "1d" $data_file
if [ $? -ne 0 ]; then
        log_error "problem with removing the header line from $data_file"
else
	row_cnt=$(wc -l $data_file | awk '{ print $1 }')
	if [ $? -ne 0 ]; then
        	log_error "problem with awk in row_cnt variable creation"
	else
		if [ $header_cnt -ne $row_cnt ]; then
			log_error " header data file and no header data file counts match: $header_cnt != $row_cnt"
		else	
			log_info "header data file and no header data file row counts match: $header_cnt = $row_cnt"
		fi	
		if [ $cntrl_cnt -ne $row_cnt ]; then
			log_error "control file row count and no header data file row count do not match: $cntrl_cnt rows != $row_cnt"
		else	
			log_info "control file row count and no header data file row count match: $cntrl_cnt rows = $row_cnt"
		fi
	fi	
fi

# remove all files from load dir
cleanup_files $load_dir
if [ $? -ne 0 ]; then
        log_error "failed to clean up $load_dir"
else
        log_info "cleaned up $load_dir to prepare for data file"

fi

# move data file from split dir to load dir
mv $split_dir$data_file $load_dir
if [ $? -ne 0 ]; then
       	log_error "move of $data_file from $split_dir to $load_dir encountered an error"
else
       	log_info "move of $data_file from $split_dir to $load_dir completed"
fi

# remove all files from split dir
cleanup_files $split_dir
if [ $? -ne 0 ]; then
        log_error "failed to clean up $split_dir"
else
        log_info "cleaned up $split_dir for next load cycle"
fi

# check the database connection is still there
conn="select test from loadlogs.test_conn;"
rs=$(db_conn $conn)
if [ $? -ne 0 ]; then
        log_error "db_conn() method failed to make a initial connection"
else
        echo $rs | grep -i "okay"
        if [ $? -ne 0 ]; then
                log_error "db connection test failed on $conn"
        else
                log_info "db connection test passed with $conn"
        fi
fi

# load that data!
log_info "$load_dir is ready to process control file: $cntrl_file and data file: $data_file"
rs=(db_conn $test_conn)
if [ $? -ne 0 ]; then
	log_error "data load of $stmt failed"
else
	if [ "$rs" != "" ]; then
		log_error "database load of $stmt failed"
	else
		log_info "database load of $stmt completed"
	fi
fi

# data has been processed so copy $upload_file from $wait_dir to $done_dir
cp $wait_dir$upload_file $done_dir
if [ $? -ne 0 ]; then
	log_error "problem with copy of $upload_file to $done_dir"
fi

# cleanup $upload_file from $wait_dir
cleanup_files $wait_dir $upload_file
if [ $? -ne 0 ]; then
	log_error "clean of $upload_file from $wait_dir failed"
fi

log_end "email_success"
