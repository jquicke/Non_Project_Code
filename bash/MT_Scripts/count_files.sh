#!/bin/bash

count_files(){
        local rtrn_cnt=0
        local cmp_dir=$1
        local cmp_file=$2
        if [ ! -n $cmp_file ]; then
                rtrn_cnt=$(ls -l $cmp_dir | grep -v -i "^total" | awk '{ print $9 }' | wc -l)
                if [ $? -ne 0 ]; then
                        echo -n "count_files() failed for directory $cmp_dir"
                fi
        else
                rtrn_cnt=$(ls -l $cmp_dir | grep -v -i "^total" | grep -i "$cmp_file" | awk '{ print $9 }' | wc -l)
                if [ $? -ne 0 ]; then
                        echo -n "count_files() failed for file $cmp_file and directory $cmp_dir"
                fi
        fi
	echo -n "$rtrn_cnt"
}

bar_dir="/tmp/bar/"
foo_file="foo"
bar_file="filebar"

echo ""

echo "check value of no file...should be 5"
rtrn_cnt=$(count_files $bar_dir)
if [ $? -ne 0 ]; then 
	echo "error in first call"
else
	echo "first method 5 = $rtrn_cnt"
fi

echo ""

echo "count files named foo in /tmp/bar...should be 3"
rtrn_cnt=$(count_files $bar_dir $foo_file)
if [ $? -ne 0 ]; then 
	echo "error in second call"
else
	echo "second method 3 = $rtrn_cnt"
fi

echo ""

echo "count files named filebar in /tmp/bar...should be 0"
rtrn_cnt=$(count_files $bar_dir $bar_file)
if [ $? -ne 0 ]; then 
	echo "error in third call"
else
	echo "third method 0 = $rtrn_cnt"
fi

echo ""
