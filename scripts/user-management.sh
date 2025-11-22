#!/bin/bash
# Description: Script to manage users
# Author: tdiprima

echo "User Management Script"
echo "1. Add User"
echo "2. Delete User"
echo "3. Change Password"
read -p "Choose an option [1-3]: " option

case $option in
  1)
    read -p "Enter username to add: " username
    sudo adduser "$username"
    ;;
  2)
    read -p "Enter username to delete: " username
    sudo deluser "$username"
    ;;
  3)
    read -p "Enter username to change password for: " username
    sudo passwd "$username"
    ;;
  *)
    echo "Invalid option!"
    ;;
esac
