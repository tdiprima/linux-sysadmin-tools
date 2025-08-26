#!/bin/bash
#
# Script Name: backup.sh
# Description: Backs up files from one directory to another.
# Author: Tammy DiPrima
# Version: 1.0.0
# License: MIT
# Date: 2024-12-27
#
# Usage:
#   ./backup.sh /path/to/source /path/to/destination
#

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  echo "Usage: ./backup.sh source_dir dest_dir"
  exit 1
fi

# Positional parameters
SOURCE_DIR="$1"
DEST_DIR="$2"

# Ensure the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Source directory '$SOURCE_DIR' does not exist."
  exit 1
fi

# Create the destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
  echo "Destination directory '$DEST_DIR' does not exist. Creating it now..."
  mkdir -p "$DEST_DIR"
fi

# Generate the backup name
BACKUP_NAME="backup_$(date +'%Y%m%d_%H%M%S').tar.gz"

# Create the backup
echo "Creating backup of $SOURCE_DIR..."
tar -czvf "$DEST_DIR/$BACKUP_NAME" "$SOURCE_DIR"
echo "Backup saved to $DEST_DIR/$BACKUP_NAME"
