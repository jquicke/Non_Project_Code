#!/bin/bash

# Name: add_development_linux_users.sh
# Function: adds new users to server and assigns them sudo permissions
# Author: James Quicke
# Version: 20131003

# add additional user names here with single whitespace before and after name
users=( jquicke )

###########################
# Don't Modify Below Here #
###########################

# make sure only root can run script
if [ `whoami` != 'root' ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

rc=0

egrep -i "^opsuser" /etc/passwd > /dev/null
if [ $? -eq 1 ]; then
	useradd -m -d /home/opsuser -U -s /bin/bash opsuser || rc=$?
	echo -e "istortill@soupnumb3r1?\nistortill@soupnumb3r1?" | passwd opsuser
	echo "added user opsuser user and group opsuser"
	mkdir -p /home/opsuser/.ssh/saved_keys
	chown -R opsuser:opsuser /home/opsuser
	echo "Created home directory .ssh sub-directories for  user opsuser"
	adduser opsuser sudo
else
   echo "user opsuser and group opsuser already exist"
fi

egrep -i "^deployuser" /etc/group > /dev/null
if [ $? -eq 1 ]; then
	useradd -m -d /home/deployuser -U -s /bin/bash deployuser || rc=$?
	echo -e "veg@mitesandwichesRgr0ss!\nveg@mitesandwichesRgr0ss!" | passwd deployuser
	echo "added user deployuser and group deployuser"
	mkdir -p /home/deployuser/.ssh/saved_keys
	chown -R deployuser:deployuser /home/deployuser
	echo "Created home directory .ssh sub-directories for user deployuser"
	adduser deployuser sudo 
else
   echo "user deployuser and deployuser group already exist"
fi

# get user count from array users
uc=${#users[*]}

# initialize index variable for array and loops
i=0

# initialize stderr return code variable to non-error status
rc=0

while [ $i -lt $uc ]; do
        # check if user exists
        cat /etc/passwd | grep -i ${users[$i]} > /dev/null || rc=$?
        if [ $rc -eq 1 ] ; then
                # reset return code to success after grep did not find match
                rc=0
                useradd -d /home/${users[$i]} -U -m -s /bin/bash ${users[$i]} || rc=$?
                if [[ $rc -eq 0 ]] ; then
                        echo "Added user for ${users[$i]}"
                        echo -e "change123me!${users[$i]}\nchange123me!${users[$i]}" | passwd ${users[$i]} || rc=$?
                        chage -d 0 ${users[$i]} || rc=$?
                        if [ $rc -eq 0 ]; then
                                echo "Set password change at first login for ${users[$i]}"
                                mkdir -p /home/${users[$i]}/.ssh/saved_keys
                                if [[ $rc -eq 0 ]] ; then
                                        echo "Created home directory .ssh sub-directories for ${users[$i]}"
                                fi
                        fi
                fi
        else
                echo "Skipping adding user for ${users[$i]} because user already exists"
        fi
        i=$[$i + 1]
done

i=0
rc=0

while [ $i -lt $uc ]; do
        adduser ${users[$i]} sudo || rc=$?
    if [ $rc -eq 0 ] ; then
        echo "Added ${users[$i]} to sudo group"
    fi
    i=$[$i + 1]
done
