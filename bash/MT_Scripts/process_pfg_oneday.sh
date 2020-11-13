#!/bin/bash

# Name: process_pfg_oneday.sh
# Environment: all
# Function: perform dos2unix count rows sed awk count rows again again split rename tar mv from being_processed/split to being_processed/done directories
# Version: 20130927
# Dependency: none

upload_dir="/mnt/customer_data/not_processed/pfguser/uploads/"
split_dir="/mnt/customer_data/being_processed/pfguser/split/"
wait_dir="/mnt/customer_data/being_processed/pfguser/waiting/"
load_dir="/mnt/customer_data/being_processed/pfguser/load/"
done_dir="/mnt/customer_data/processed/pfguser/"
archieved_dir="/mnt/customer_data/processed/pfguser/archived/"
exec_file="process_pfg_oneday.sh"

load_chk=$(ls $load_dir | wc -l)
if [ $load_chk -ne 0 ]; then
        echo "not starting because $load_dir is not empty"
        exit 1;
fi

upload_chk=$(ls $upload_dir | wc -l)
if [ $upload_chk -eq 0 ]; then
        echo "no files in $upload_dir"
        exit 1
else
	if [ $upload_chk -gt 1 ]; then
		echo "more than 1 file in $upload_dir"
		exit 1
	else
	        upload_file=$(ls $upload_dir)
        	echo "okay...there is $upload_chk file in $upload_dir"
	fi
fi

zip_chck=$(file $upload_dir$upload_file | grep -i " Zip archive data")
if [[ $zip_chck == "" ]]; then
        echo "fail...$upload_file is not a zip file"
        exit 1
else
        echo "okay...$upload_file is a zip file"
fi

split_files=$(ls $split_dir)
if [ $? -ne 0 ]; then
	echo "problem with getting contents of $split_dir"
	exit 1;
else
	err_flg=0
	for file in `echo $split_files`; do
		rm $split_dir$file
		if [ $? -ne 0 ]; then
		        echo "problem deleting $file from $split_dir"
			err_flg=1
		fi
	done
	if [ $err_flg -ne 0 ]; then
		echo "cleanup of $split_dir failed"
		exit 1
	fi
fi

for dir in $done_dir $archieved_dir $split_dir; do
	cp $upload_dir$upload_file $dir
	if [ $? -ne 0 ]; then
        	echo "problem with copy of $upload_file to $dir"
	        exit 1;
	fi
done

unzip $split_dir$upload_file -d $split_dir
if [ $? -ne 0 ]; then
        echo "problem with unzip of $upload_file in $split_dir"
        exit 1;
fi

data_file=$(ls $split_dir| grep -i "MLTKTDAT")
if [ $? -ne 0 ]; then
	echo "fail...no match for data file"
	exit 1
fi

header_chk=$(head -1 $split_dir$data_file | awk 'BEGIN {FS=","} { print $1 }')
if [ $? -ne 0 ]; then
        echo "fail...problem with awk in header_chk variable creation"
        exit 1
fi

if [ "$header_chk" == "DISTRIBUTOR_NUMBER" ]; then
	echo "fail...DISTRIBUTOR_NUMBER != $header_chk"
	exit 1
fi

cntrl_file=$(ls $split_dir| grep -i "MLTKTCTL")
if [ $? -ne 0 ]; then
        echo "fail...no match for control file"
        exit 1
fi

dos2unix $split_dir$cntrl_file 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	echo "fail...dos2unix had an error"
	exit 1
fi

cntrl_cnt=$(head -1 $split_dir$cntrl_file | awk 'BEGIN {FS=","} { print $3 }')
if [ $? -ne 0 ]; then
        echo "fail...problem with awk in cntrl_cnt variable creation"
        exit 1
fi

pre_header_cnt=$(wc -l $split_dir$data_file | awk '{ print $1 }')
pre_header_cnt=$(( $pre_header_cnt - 1 ))

if [ $pre_header_cnt -ne $cntrl_cnt ]; then
        echo "fail...$pre_header_cnt = $cntrl_cnt so data file and control file row counts do not match"
        exit 1
else
	sed -i -e "1d" $split_dir$data_file
	post_header_cnt=$(wc -l $split_dir$data_file | awk '{ print $1 }')
fi

if [ $pre_header_cnt -ne $post_header_cnt ]; then
	echo "fail...$pre_header_cnt = $post_header_cnt so pre-sed and post-sed data file row counts do not match"
	exit 1
else	
	echo "okay...$pre_header_cnt = $post_header_cnt so pre-sed and post-sed data file row counts match"
fi

if [ $cntrl_cnt -ne $post_header_cnt ]; then
	echo "fail...cntrl_cnt rows = $post_header_cnt rows so control files and post-sed row counts do not match"
	exit 1
else	
	echo "okay...$cntrl_cnt = $post_header_cnt control file and post-sed row counts match"
fi

awk -F, '{print > $1}' $split_dir$data_file
if [ $? -ne 0 ]; then
        echo "awk of $data_file in $split_dir failed"
fi

# move them out
flag=0
mv $split_dir100 $split_dir15_100_afi.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir125 $split_dir13_125_ccounty.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir130 $split_dir234_130_hale.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir140 $split_dir237_140_lester.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir161 $split_dir238_161_middendorf.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir165 $split_dir235_165_littlerock.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir166 $split_dir239_166_batesville.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir170 $split_dir236_170_springfield.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir240 $split_dir240_240_powell.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir300 $split_dir241_300_empiresf.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir410 $split_dir242_410_arizona.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir412 $split_dir243_412_dallas.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir414 $split_dir233_414_denver.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir421 $split_dir244_421_minnesota.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir425 $split_dir231_425_nocal.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir427 $split_dir230_427_portland.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir429 $split_dir246_429_springfield.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi
mv $split_dir431 $split_dir17_431_philly.csv
if [ $? -ne 0 ]; then
        echo "rename of load files in $split_dir failed"; flag=(( $flag + 1 ));
fi

if [ $flag -ne 0 ]; then
	echo "csv file rename encountered $flag errors"
else
	echo "csv file rename had $flag errors"
fi

# cleanup data, control, and upload files from split dir
flag=0
for file in $data_file $cntrl_file $upload_file; do
                rm -f $split_dir$file
                if [ $? -ne 0 ]; then
                        echo "problem deleting $file from $split_dir"
                        flag=1
                fi
done
if [ $flag -ne 0 ]; then
	echo "post split cleanup of $split_dir failed"
	exit 1
fi

chmod 666 $split_dir*
if [ $? -ne 0 ]; then
        echo "chmod of $load_dir failed"
        exit 1
fi

chown opsuser:opsuser $split_dir*
if [ $? -ne 0 ]; then
        echo "chown of $load_dir failed"
        exit 1
fi

mv $split_dir* $load_dir
if [ $? -ne 0 ]; then
	echo "move of load files from $split_dir to $done_dir failed"
	exit 1
fi

split_cnt=$(ls $split_dir | wc - l)
if [ $split_cnt -ne 0 ]; then
        echo "There are $split_cnt unrecognized files remaining in $split_dir"
	unamed_files=$(ls $split_dir)
	echo "unamed files: $unamed_files"
	exit 1
fi

rm $uploads_dir$upload_file
if [ $? -ne 0 ]; then
        echo "rm of $upload_file in $uploads_dir failed"
	exit 1
fi

echo "done!"
exit 0
