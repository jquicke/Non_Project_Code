#!/bin/bash

# Name remove_sftp_users.sh
# Function: remove customer SFTP accounts and SFTP group
# Version: 09.07.13

# make sure only root can run script
if [ `whoami` != 'root' ]; then
        echo "This script must be run as root"
        exit 1
fi

egrep -i "^mcdonaldftp" /etc/passwd > /dev/null
if [ $? -eq 0 ]; then
        deluser mcdonaldftp
        rm -r /mnt/customer_data/not_processed/mcdonaldftp
        echo "removed user mcdonaldftp"
else
        echo "user mcdonaldftp does not exist"
fi

egrep -i "^pfguser" /etc/passwd > /dev/null
if [ $? -eq 0 ]; then
        deluser pfguser
        rm -r /mnt/customer_data/not_processed/pfguser
        echo "removed user pfguser"
else
        echo "user pfguser does not exist"
fi

egrep -i "^shetakisuser" /etc/passwd > /dev/null
if [ $? -eq 0 ]; then
        deluser shetakisuser
        rm -r /mnt/customer_data/not_processed/shetakisuser
        echo "removed user shetakisuser"
else
        echo "user shetakisuser does not exist"
fi