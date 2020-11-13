#!/bin/bash

# Name: process_sftp_data.sh
# Function: load the daily data into distinct OPCO files
# Version: 20130912
# Dependency: sftp_log_library 20130911
# Dependency: sftp_load_library 20130911

# make sure only root can run script
if [ `whoami` != "root" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
fi

# set library and executable paths
main_fctn="process_sftp_data.sh"
load_lib="sftp_load_library"
log_lib="sftp_log_library"
lib_path="/mnt/automation/etl_scripts/sftp_loads_server/"
etl_dir="/mnt/automation/etl_scripts/sftp_loads_server/"

# check the library versions
echo "Starting pre-load checks
for lib in $load_lib $log_lib; do
	echo "Checking for correct $lib library version"
	if [ ! -f $lib_path$lib ]; then
        	echo "ERROR: $lib does not exist in $log_path or does not have read/write permissions"
        	exit 0;
	else
        	log_lib_ver_req=$(grep -i -h "^# Dependency: sftp_log_library" $lib_path/$main_fctn | awk '{ print $4 }')
        	log_lib_ver=$(grep -i -h "^# Version:" $lib_path/$lib | awk '{ print $3 }')
        	if [[ $log_lib_ver -lt $log_lib_ver_req ]]; then
                	echo "ERROR: $lib in $lib_path is version $log_lib_ver and version $log_lib_ver_req is required"
                	exit 0
		else
        		echo "log library version is correct"
        	fi
	fi
done

# initialize libraries
. $etl_dir$log_lib
. $etl_dir$load_lib
set_log_variables
set_load_variables

# set local variables
pfg_not_proc="/mnt/customer_data/not_processed/pfguser/uploads/"
pfg_split="/mnt/customer_data/being_processed/pfguser/split/"
pfg_load="/mnt/customer_data/being_processed/pfguser/load/"
pfg_waiting="/mnt/customer_data/being_processed/pfguser/waiting/"
pfg_done="/mnt/customer_data/processed/pfguser/data/"

# begin work
log_start "starting up!"

# check data paths
log_info "check data filepaths"

for path in $pfg_not_proc $pfg_split $pfg_load $pfg_done; do
	if [ ! -d $path ]; then
        	log_error "$path does not exist or does not have read/write permissions"
        	exit 0
	else
        	log_info "$path exists and has read/write permissions"
	fi
done

pfg_orig_files=$(ls $pfg_not_proc)

for file in $pfg_orig_files; do
	log_info "found upload file $file in $pfg_not_proc"
	pfg_orig_filesize=$(ls -l $pfg_not_proc$file | grep -v "^total" | awk '{ print $5 }')
	log_info "starting copy of file $file to $pfg_done"
	cp $pfg_not_proc$file $pfg_done
	log_info "finished copy of file $file to $pfg_done"
	log_info "starting copy of file $file to $pfg_split"
	cp $pfg_not_proc$file $pfg_split
	log_info "finished copy of file $file to $pfg_split"
	pfg_done_filesize=$(ls -l $pfg_done$file | grep -v "^total" | awk '{ print $5 }')
	pfg_split_filesize=$(ls -l $pfg_split$file | grep -v "^total" | awk '{ print $5 }')
	if [ $pfg_done_filesize -ne $pfg_orig_filesize ]; then
        	log_error "archived version $file in $pfg_done is not the same byte count as the original file $file...exiting now"
        	exit 0
	else
		log_info "archived version $file ($pfg_done_filesize bytes) size matches original file $file ($pfg_orig_filesize bytes)"
		if [ $pfg_split_filesize -ne $pfg_orig_filesize ]; then
        		log_error "working copy version of $file in $pfg_split does not have the same byte count as original file $file...exiting now"
        		exit 0
		else	
			log_info "working copy version $file ($pfg_split_filesize bytes) size matches original file $file ($pfg_orig_filesize bytes)"
			log_info "file copies of archive and working copy of $file complete!"	
		fi
fi

rm -f $pfg_not_proc
log_info "cleaned up $pfg_not_proc directory"

## commented out unzip process for the moment as files should be ascii text not binary zips
##log_info "starting unzip of $pfg_orig_file in $pfg_split"
##unzip $pfg_split$pfg_orig_file -d $pfg_split
##log_info "finished unzipping of $pfg_orig_file in $pfg_split"
##rm $pfg_split$pfg_orig_file
##log_info "cleaned up $pfg_orig_file from $pfg_split"	

filename_array=$(ls $pfg_split)

# cheat like a dog (or hack like an amateur) because I'm fed up with shell errors (should have used python)
cd $pfg_split

pfg_data_file=$(for file in `echo $filename_array` ; do grep -l -m1 -i "^DISTRIBUTOR_NUMBER*" $file ; done)
log_info "found data file $pfg_data_file in $pfg_split"

pfg_ctl_file=$(ls -I$pfg_data_file $pfg_split)
log_info "found control file $pfg_ctl_file in $pfg_split"

# get control file row count and strip nasty carriage return
pfg_ctl_rowcnt=$(cut -d "," -f3 "$pfg_ctl_file")
pfg_ctl_rowcnt=$(echo $pfg_ctl_rowcnt | sed 's/.$//')

# strip header from data file and count rows
sed -i -e "1d" $pfg_data_file
pfg_data_rowcnt=$(cat $pfg_data_file | wc -l)

log_info "control file rowcount = $pfg_ctl_rowcnt"
log_info "data file rowcount = $pfg_data_rowcnt"

if [ $pfg_ctl_rowcnt -eq $pfg_data_rowcnt ]; then
	log_info "data file count ($pfg_data_rowcnt rows) equals control file count ($pfg_ctl_rowcnt rows)"
else
	log_error "data file count ($pfg_data_rowcnt rows) does not equal control file count ($pfg_ctl_rowcnt rows)"
	exit 0
fi

# change file ownership
chown opsuser:opsuser $pfg_split*
chown opsuser:opsuser $pfg_load*
chown opsuser:opsuser $pfg_waiting*

# more cheating like a dog and change back to original directory
cd $etl_script_dir

#################
## main() code ##
#################

log_end "Finished processing"

exit 0
