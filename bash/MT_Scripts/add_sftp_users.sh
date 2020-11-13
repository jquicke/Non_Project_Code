#!/bin/bash

# Name add_sftp_users.sh
# Function: add customer SFTP accounts
# Version: 09.07.13

# add additional user names here with single whitespace before and after name
users=( mcdonaldftp pfguser shetakisuser pfgphilly )
#passwords=( mcD0naldwhsl pFgus3rMe@L L4sV3g4s2013 dIg!talr3x654 )
passwords=( mcD0naldwhsl pFgus3rpMea! L4sV3g4s2013 dIg!talr3x654 )

###########################
# Don't Modify Below Here #
###########################

# make sure only root can run script
if [[ `whoami` != 'root' ]]; then
        echo "This script must be run as root"
        exit 1
fi

# make sure there is a password for every user
if [[ ${#users[*]} -ne ${#passwords[*]} ]] ; then
        echo "Count of users and passwords is not equal."
        exit 1
fi

# get user count from array users
uc=${#users[*]}

# initialize index variable for array and loops
i=0

# initialize stderr return code variable to non-error status
rc=0

# create unix group if it doesn't exist
cat /etc/group | grep sftponly > /dev/null || rc=$?
if [[ $rc -eq 1 ]] ; then
        echo "Creating 'sftponly' group."
        addgroup sftponly
        rc=0
else
        echo "Group 'sftponly' already exists."
fi

mkdir -p /mnt/customer_data/not_processed

while [ $i -lt $uc ]; do
        # check if user exists
        cat /etc/passwd | grep -i ${users[$i]} > /dev/null || rc=$?
        if [ $rc -eq 1 ] ; then
                #reset return code to success after grep did not find match
                rc=0
                useradd -d /mnt/customer_data/not_processed/${users[$i]} -m -N -g sftponly ${users[$i]}
                if [ $rc -eq 0 ] ; then
                        echo "Added user for ${users[$i]}"
                        echo -e "${passwords[$i]}\n${passwords[$i]}" | passwd ${users[$i]} || rc=$?
                        if [ $rc -eq 0 ] ; then
                                echo "Set password for ${users[$i]}"
                                # root must own the user's home directory, but the user owns the uploads dir
                                chown root:root /mnt/customer_data/not_processed/${users[$i]}
                                mkdir -p /mnt/customer_data/not_processed/${users[$i]}/uploads
                                chown ${users[$i]}:sftponly /mnt/customer_data/not_processed/${users[$i]}/uploads
				# allow sftp group members i.e. ops staff to remove files from sftp uploads directories as default permissions are 755
				chmod 735 /mnt/customer_data/not_processed/${users[$i]}/uploads
                                for dow in `seq 1 7`
                                do
                                        mkdir -p /mnt/customer_data/processed/${users[$i]}/day$dow/data
                                done
                                chown -R opsuser:opsuser /mnt/customer_data/processed/${users[$i]}
                        fi
                fi
        else
                echo "Skipping adding user for ${users[$i]} because user already exists"
        fi
        i=$[$i + 1]
done

echo "Done"
echo "If /etc/ssh/sshd_config hasn't been modified, make the following changes to the bottom of sshd_config"
echo "Remove the line 'Subsystem sftp /usr/lib/openssh/sftp-server' and add the following in place of it:

# Commented out to allow internal sftp group shroot jail
#Subsystem sftp /usr/lib/openssh/sftp-server

Subsystem sftp internal-sftp

Match group sftponly
ChrootDirectory %h
X11Forwarding no
AllowTcpForwarding no
ForceCommand internal-sftp
";
