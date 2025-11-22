#!/bin/bash
#
# create_users_from_list.sh
#
# Description:
#   Batch creates user accounts from a text file, one username per line.
#   Each user is created with a home directory and assigned a default password.
#
# Usage:
#   sudo ./create_users_from_list.sh
#
# Requirements:
#   - Input file: userlist.txt (one username per line)
#   - Root/sudo privileges required
#
# Output:
#   - Log file: created_users.log
#
# Security Note:
#   All users are created with the same default password.
#   Users should be required to change their password on first login.
#

# Input file containing usernames
USERFILE="userlist.txt"
# Default password
DEFAULT_PASS="12345678"
# Log file
LOGFILE="created_users.log"
# Clear or create log file
> $LOGFILE
while IFS= read -r USERNAME
do
    if id "$USERNAME" &>/dev/null; then
        echo "User $USERNAME already exists. Skipping..."
    else
        useradd -m "$USERNAME"
        echo "$USERNAME:$DEFAULT_PASS" | chpasswd
        echo "Created user: $USERNAME" | tee -a $LOGFILE
    fi
done < "$USERFILE"
echo "User creation process complete. Check $LOGFILE for details."
