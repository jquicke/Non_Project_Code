#!/bin/bash

# Name: process_sftp_data.sh
# Environment: all
# Function: process and load a single day of pfg data
# Version: 20130926
# Dependency: .my.pass 20130923
# Utility: unzip
# Utility: unix2dos
# Utility: file

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

load_user="dataloader"
admin_user="dbadmin"
mt_user="mtadmin"
load_pass=$(cat .my.pass | grep -i "dataloader" | awk '{ print $2 }')
admin_pass=$(cat .my.pass | grep -i "dbadmin" | awk '{ print $2 }')
mt_pass=$(cat .my.pass | grep -i "mtadmin" | awk '{ print $2 }')
db_instance=$(cat .my.pass | grep -i "instance" | awk '{ print $2 }')

uploads_dir="/mnt/customer_data/not_processed/$sftpuser/uploads/"
split_dir="/mnt/customer_data/being_processed/$sftpuser/split/"
wait_dir="/mnt/customer_data/being_processed/$sftpuser/waiting/"
load_dir="/mnt/customer_data/being_processed/$sftpuser/load/"
done_dir="/mnt/customer_data/processed/$sftpuser/"
log_dir="/var/log/dataload/"
paths="$uploads_dir $split_dir $wait_dir $load_dir $done_dir"

ymd=$(date +%Y%m%d%H%M%S)
log=$(echo "process_"$sftpuser"_data_log.$ymd")

exec_list=$(cat $script | grep "# Utility:" $script | /usr/bin/awk '{ print $3 }' | sed 's/|//g')

email_success="success...$script log for $host on $ymd"
email_failure="failure...$script log for $host on $ymd"

script_start_time=$(date +%s)

######################
## define functions ##
######################

## timing functions

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

## logging functions

start_log(){
	local message="$1"
	local interval=$(get_interval)
        echo "$interval	START:	$message" >> $log_dir$log
	if [ $? -ne 0 ]; then
		echo "$interval	ERROR:	start_log() called with $message failed"
		echo "$interval	END:	exiting $script!!!"
	else
		log_info "passed logging test"
	fi
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
	end_log "failure!" 
}

log_wtf(){
        local message="$1"
        local interval=$(get_interval)
        echo "$interval WTF:  $message" >> $log_dir$log
        echo "$interval WTF:  Exiting with dirty end_log()" >> $log_dir$log
	exit 1
}

email_log(){
	local email_subject="$1"
	local mail_chk=""
        if echo $email_subject | grep -i -q "success" ; then
                mail_chk=$(mail -s "$email_success" $notify_list < $log_dir$log)
	else
		if echo $email_subject | grep -i -q "failure" ; then
	                mail_chk=$(mail -s "$email_failure" $notify_list < $log_dir$log)
	        else
			mail_chk=$(mail -s "$email_subject" $notify_list < $log_dir$log)
		fi
	fi
}

end_log(){
        local message="$1"
	local interval=$(get_interval)
	get_elapsed $script_start_time
        echo "$interval	END:	$message" >> $log_dir$log
        email_log $message
	if [ $? -ne 0 ]; then
		log_wtf="email_log() called in end_log() with a non null return code"
	fi
	if echo $message | grep -i -q "success" ; then
		exit 0
	else
		exit 1
	fi
}

## validation functions

test_log(){
	if [ ! -d $log_dir ]; then
        	echo "$interval	ERROR:	log directory $log_dir does not exist or does not have read/write permissions: test_log() failed"
		echo "$interval ERROR:	exiting $script!!!"
		exit 1
	fi
}

test_dir(){
        local test_dir=$1
        if [ ! -d $test_dir ]; then
		log_error "test_dir() for directory $test_dir failed"
        fi
}

test_paths(){
	local dir=""
	for dir in `echo $paths`; do
        	test_dir $dir
		if [ $? -ne 0 ]; then
			log_error "test_paths() at test_dir() for dir $dir failed"
		fi
        done
	log_info "passed file path tests"
}

test_exec(){
	local test_val=0
	for util in `echo $exec_list`; do
		which $util 1>/dev/null
                if [ $? -ne 0 ]; then
                        log_warn "executable $util is not installed or not executable"
			test_val=1
                fi
	done
	if [ $test_val -ne 0 ]; then
		log_error "test_exec() for $exec_list failed"
	else
		log_info "passed executable check tests"
	fi
}

## utility functions

count_files(){
        local rtrn_cnt=0
        local cnt_dir=$1
        local cnt_file=$2
	test_dir $cnt_dir
        if [ ! -n $cnt_file ]; then
                rtrn_cnt=$(ls -l $cnt_dir | grep -v -i "^total" | awk '{ print $9 }' | wc -l)
                if [ $? -ne 0 ]; then
                        echo "count_files() for directory $cnt_dir failed"
                fi
        else
                rtrn_cnt=$(ls -l $cnt_dir | grep -v -i "^total" | grep -i "$cnt_file" | awk '{ print $9 }' | wc -l)
                if [ $? -ne 0 ]; then
                        echo "count_files() for file $cnt_file and directory $cnt_dir failed"
                fi
        fi
        echo "$rtrn_cnt"
}

cleanup_files(){
        local rtrn_val=0
	local cln_dir=$1
	local cln_files=$2
        local warn_val=0
	test_dir $cln_dir
	if [ $? -ne 0 ]; then
		log_error "test_dir() inside of cleanup_files() failed"
	fi
	if [ ! -n "$cln_files" ]; then
		rm -f $cln_dir*
		if [ $? -ne 0 ]; then
                        log_warn "cleanup_files() for directory $cln_dir failed"
			warn_val=1
                fi
	else
		for file in `echo $cln_files`; do
			rm -f $cln_dir$file
			if [ $? -ne 0 ]; then
                	        log_warn "deletion of file $file from directory $cln_dir failed"
				warn_val=1
			fi
		done
	fi		
	if [ $warn_val -ne 0 ]; then
		log_error "cleanup_files() for $cln_dir and $cln_files failed"
		rtrn_val=$warn_val
	fi
	echo "$rtrn_val"
}

unzip_file(){
	local zip_dir=$1
	local zip_file=$2
	local zip_chk=""
	test_dir $zip_dir	
	zip_chk=$(file $zip_dir$zip_file | grep -i -v "Zip")
	if [ -n "$zip_chk" ]; then
		log_error "check_zip() in check for null (directory = $zip_dir) (file = $zip_file) failed"
	else
		unzip $zip_dir$zip_file -d $zip_dir
		if [ $? -ne 0 ]; then
			log_error "unzip of $zip_file in $zip_dir failed"
		else
			log_info "completed unzip of $zip_file in $zip_dir"
		fi
	fi
}

## database functions

db_conn(){
	local stmt="$1"
	local rs=""
        rs=$(mysql -u$load_user -p$load_pass -h$db_instance -e"$stmt")
        if [ $? -ne 0 ]; then
                log_error "db conn() for $stmt failed"
        fi
        echo "$rs"        
}

test_db_conn(){
	local rs=""
	local test_stmt="select test from loadlogs.test_conn;" 
	rs=$(db_conn "$test_stmt" | grep -i "okay")
	if [ $? -ne 0 ]; then
        	log_error "db_conn() initial connection inside test_db_conn() failed"
	else
                rs=$(echo $rs | grep -i -v "okay")
		if [ $? -ne 1 ]; then
			log_error "test_db_conn() on $test_stmt in result set grep failed (rs = $rs)"
		else
			if [ "$rs" != "" ]; then
				log_error "test_db_conn() on $test_stmt failed"
			else
				log_info "passed database connection tests"
        		fi
		fi
	fi
}

############
## main() ##
############

# test logging 
test_log
if [ $? -ne 0 ]; then
	echo "$interval	ERROR:	test_log() failed"
	echo "$interval	ERROR:	exiting $script!!!"
	exit 1
fi

# start log
start_log "starting up $script"
if [ $? -ne 0 ]; then
        log_error "start_log() failed"
fi

# test executables
test_exec
if [ $? -ne 0 ]; then
        log_error echo "test_exec() failed"
fi

# test file paths
test_paths
if [ $? -ne 0 ]; then
        log_error echo "test_paths() failed"
fi

# test db connection
test_db_conn
if [ $? -ne 0 ]; then 
	log_error "test_db_connection() failed" 
fi

# test for existing load processes
# stub

# check sftp dir for single, fully uploaded sftp file
file_chk=$(count_files $uploads_dir)
if [ $? -ne 0 ]; then 
	log_error "count_files() check for single file in $uploads_dir failed"
else
	if [ $file_chk -ne 1 ]; then
		if [ $file_chk -gt 1 ]; then
			log_error "there is more than 1 file in $uploads_dir (file_count = $file_chk)"
		else
			log_error "there are no files in $uploads_dir (file_count = $file_chk)"
		fi
	else
		log_info "correct number of files in $uploads_dir"
	fi
fi

# get the name of uploaded file
upload_file=$(ls $uploads_dir)
if [ $? -ne 0 ]; then 
	log_error "assignment of upload_file variable for file in $uploads_dir failed"
fi

# remove all files from split dir
cleanup_files $split_dir
if [ $? -ne 0 ]; then
        log_error "clean_up() $split_dir failed"
fi	

# copy uploaded file to waiting directory to save it, copy uploaded file to split directory for processing
for dir in $wait_dir $split_dir; do 
	cp $uploads_dir$upload_file $dir
	if [ $? -ne 0 ]; then
		log_error "copy of $upload_file from $uploads_dir to $dir failed"
	else
		log_info "completed copy of $upload_file to $dir"
	fi
done

# remove uploaded file from sftp uploads dir
cleanup_files $uploads_dir $upload_file
if [ $? -ne 0 ]; then
        log_error "cleanup_files() for $upload_file from $uploads_dir failed"
fi

# unzip uploaded file in split dir
unzip_file $split_dir $upload_file
if [ $? -ne 0 ]; then
        log_error "unzip_file() using $upload_file and $split_dir failed"
fi

# remove uploaded file from split dir
cleanup_files $split_dir $upload_file
if [ $? -ne 0 ]; then
        log_error "cleanup_files() for $upload_file from $split_dir failed"
fi

# count the unzipped files
unzip_cnt=$(count_files $split_dir)
if [ $? -ne 0 ]; then
        log_error "count_files() for unzipped files from $split_dir failed"
else
	if [ $unzip_cnt -ne "2" ]; then
		log_error "unzip of $upload_file did not result in 2 unzipped files in $split_dir (file count = $unzip_cnt)"
	fi
fi

# find the data file, grab the first column of the header row, and validate it
data_file=$(ls $split_dir | grep -i "MLTKTDAT")
if [ $? -ne 0 ]; then
	log_error "error looking for data file in $split_dir"
else
	header_chk=$(head -1 $split_dir$data_file | awk 'BEGIN {FS=","} { print $1 }')
	if [ $? -ne 0 ]; then
        	log_error "error with awk during header_chk variable creation"
	else
		if [ "$header_chk" != "DISTRIBUTOR_NUMBER" ]; then
        		log_error "header DISTRIBUTOR_NUMBER != $header_chk"
		fi
	fi
fi

# find the control file, sanitize that nasty thing, and get a row count
cntrl_file=$(ls $split_dir | grep -i "MLTKTCTL")
if [ $? -ne 0 ]; then
        log_error "error looking for control file in $split_dir"
else
	dos2unix $split_dir$cntrl_file 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		log_error "problem with dos2unix of control file $cntrl_file in $split_dir"
	else
		cntrl_cnt=$(head -1 $split_dir$cntrl_file | awk 'BEGIN {FS=","} { print $3 }')
		if [ $? -ne 0 ]; then
		        log_error "problem with awk of cntrl_cnt variable creation"
		fi
	fi
fi

# count the data file row count, subtract 1 row in awk to allow for header row that will be stripped, compare results
header_cnt=$(wc -l $split_dir$data_file | awk '{ print $1 }')
if [ $? -ne 0 ]; then
        log_error "problem with awk in header_cnt variable creation"
else
	# subtracting one row from row count to allow for header row
	header_cnt=$(($header_cnt - 1))	
	if [ $header_cnt -ne $cntrl_cnt ]; then
        	log_error "original data file minus header and control file row counts do not match: $header_cnt != $cntrl_cnt"
	fi
fi

# strip the header from the data file, get row counts, compare results
sed -i -e "1d" $split_dir$data_file
if [ $? -ne 0 ]; then
        log_error "problem with removing the header line from $data_file"
else
	row_cnt=$(wc -l $split_dir$data_file | awk '{ print $1 }')
	if [ $? -ne 0 ]; then
        	log_error "problem with awk in row_cnt variable creation"
	else
		if [ $header_cnt -ne $row_cnt ]; then
			log_error "original data file minus header and data file counts do not match: $header_cnt != $row_cnt"
		else	
			if [ $cntrl_cnt -ne $row_cnt ]; then
				log_error "control file row count and data file row count do not match: $cntrl_cnt != $row_cnt"
			else	
				log_info "correct control file and data file row counts"
			fi
		fi
	fi	
fi

# remove all files from load dir
cleanup_files $load_dir
if [ $? -ne 0 ]; then
        log_error "failed to clean up $load_dir"
fi

# copy data file from split dir to load dir
cp "$split_dir$data_file" $load_dir
if [ $? -ne 0 ]; then
       	log_error "copy of $data_file from $split_dir to $load_dir failed"
fi

# remove all files from split dir
cleanup_files $split_dir
if [ $? -ne 0 ]; then
        log_error "cleanup_files() of $split_dir failed"
fi

# signal everything is ready
log_info "load: sftp_file = $upload_file control_file = $cntrl_file data_file = $data_file row_count = $row_cnt"

# load that data!
stmt="select test from loadlogs.test_conn;"
rs=$(db_conn "$stmt")
if [ $? -ne 0 ]; then
	log_error "db_conn for $stmt failed"
else
	rs=$(echo $rs | tr '\n' ' ')
	if [ $? -ne 0 ]; then
		log_error "database load of $stmt failed"
	else
		log_info "completed database load"
	fi
fi

# data has been processed so copy $upload_file from $wait_dir to $done_dir
cp $wait_dir$upload_file $done_dir
if [ $? -ne 0 ]; then
	log_error "copy of $upload_file to $done_dir failed"
fi

# cleanup $upload_file from $wait_dir
cleanup_files $wait_dir $upload_file
if [ $? -ne 0 ]; then
	log_error "cleanup_files() of $upload_file from $wait_dir failed"
fi

end_log "success!"
