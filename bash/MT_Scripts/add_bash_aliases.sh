# Name: add_bash_aliases.sh
# Environment: all
# Path: /mnt/automation/user_scripts
# User: root
# Function: creates aliases file with additional variables and aliases for specified user listed under "set user variables" comment block
# Author: jquicke
# Version: 20130929

########################
## set user variables ##
########################

user="root"

###################################
## don't modify below this point ##
###################################

# get version of this script to add to .bash_aliases file that is created
script=$(basename $0)
version=$(grep "^# Version: " $script | grep -v "echo" | awk '{ print $3 }')

# get user home directory
home=$(grep "$user" /etc/passwd | awk -F: '{ print $6 }')
aliases="$home/.bash_aliases"

# create a new file or empty an existing one
if [ -f $aliases ]; then
	cat /dev/null > $aliases
else
	touch $aliases
fi

chown $user:$user $aliases
chmod 0640 $aliases

# add file contents dynamically

echo "# Name: .bash_aliases" >> $aliases
echo "# Environment: all" >> $aliases
echo "# Path: $home" >> $aliases
echo "# User: $user" >> $aliases
echo "# Function: creates additional shell variables and aliases" >> $aliases
echo "# Author: jquicke" >> $aliases
echo "# Version: $version" >> $aliases
echo "" >> $aliases
echo "# set sftp variables for pfg" >> $aliases
echo "" >> $aliases
echo "uploads_dir=\"/mnt/customer_data/not_processed/pfguser/uploads/\"" >> $aliases
echo "split_dir=\"/mnt/customer_data/being_processed/pfguser/split/\"" >> $aliases
echo "wait_dir=\"/mnt/customer_data/being_processed/pfguser/waiting/\"" >> $aliases
echo "load_dir=\"/mnt/customer_data/being_processed/pfguser/load/\"" >> $aliases
echo "done_dir=\"/mnt/customer_data/processed/pfguser/\"" >> $aliases
echo "archived_dir=\"/mnt/customer_data/processed/pfguser/archived/\"" >> $aliases
echo "" >> $aliases
echo "export uploads_dir split_dir wait_dir load_dir done_dir archived_dir" >> $aliases
echo "" >> $aliases
echo "# aliases for changing to sftp directories" >> $aliases
echo "" >> $aliases
echo "alias pfg_uploads='cd \$uploads_dir'" >> $aliases
echo "alias pfg_split='cd \$split_dir'" >> $aliases
echo "alias pfg_wait='cd \$wait_dir'" >> $aliases
echo "alias pfg_load='cd \$load_dir'" >> $aliases
echo "alias pfg_done='cd \$done_dir'" >> $aliases
echo "alias pfg_archived='cd \$archived_dir'" >> $aliases
