#!/bin/sh

# copy files to servers

for

scp ./create_automation_directories.sh dev-app-001:/tmp
scp ./create_automation_directories.sh dev-sql-001:/tmp
scp ./create_automation_directories.sh prd-sql-001:/tmp
scp ./create_automation_directories.sh prd-app-001:/tmp
scp ./create_automation_directories.sh prd-utl-001:/tmp
