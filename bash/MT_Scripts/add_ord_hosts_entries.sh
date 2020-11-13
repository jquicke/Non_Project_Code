#!/bin/bash

# Name: add_ord_hosts_entries.sh
# Environment: all
# Facility: ord
# Function: add host file entries to ord facility servers
# Version: 20131004

dest_file="/etc/hosts"

echo"" >> $dest_file
echo "# production"
echo "10.178.134.66   prd-sql-001" >> $dest_file
echo "10.178.193.91   prd-app-001" >> $dest_file
echo"" >> $dest_file
echo "# staging" >> $dest_file
echo"" >> $dest_file
echo "# development" >> $dest_file
echo "10.178.139.95   dev-sql-001" >> $dest_file
echo "10.178.20.88    dev-app-001" >> $dest_file
