#!/bin/bash
# Description: Script to find and rename files
# Author: tdiprima

echo "File Operations"
echo "1. Find duplicate files"
echo "2. Batch rename files"
read -p "Choose an option [1-2]: " option

case $option in
  1)
    read -p "Enter directory to search for duplicates: " dir
    find "$dir" -type f -exec md5sum {} + | sort | uniq -w32 -d
    ;;
  2)
    read -p "Enter directory to rename files: " dir
    read -p "Enter prefix for files: " prefix
    count=1
    for file in "$dir"/*; do
      mv "$file" "$dir/$prefix$count.${file##*.}"
      count=$((count + 1))
    done
    echo "Files renamed."
    ;;
  *)
    echo "Invalid option!"
    ;;
esac
