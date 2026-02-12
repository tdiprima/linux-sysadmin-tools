#!/bin/bash
# Search for duplicates or find and rename files

echo "File Operations"
echo "1. Find duplicate files"
echo "2. Batch rename files"
read -p "Choose an option [1-2]: " option

case $option in
  1)
    read -p "Enter directory to search for duplicates: " dir
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS version using md5
      find "$dir" -type f -exec md5 -r {} + | sort | awk 'BEGIN{prev=""} {if($1==prev){print} prev=$1}'
    else
      # Linux version using md5sum
      find "$dir" -type f -exec md5sum {} + | sort | uniq -w32 -d
    fi
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
