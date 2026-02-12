#!/usr/bin/env bash
# Description: Update GitHub repositories

# Base directory to start searching
BASE_DIR="/path/to/directory"

# Counter for repositories processed
COUNT=0

# Start the process
echo -e "\\n\\033[1mStarting to pull latest changes for repositories in $BASE_DIR...\\033[0m\\n"

# Use a for-loop to avoid subshells and ensure COUNT is updated in the current shell
for GIT_DIR in $(find "$BASE_DIR" -type d -name ".git" -prune); do
  REPO_DIR=$(dirname "$GIT_DIR")
  echo -e "\\033[34mProcessing repository in: $REPO_DIR\\033[0m"

  # Navigate to the repository directory
  if cd "$REPO_DIR"; then
    echo -e "\\033[33mPulling latest changes...\\033[0m"
    git pull && echo -e "\\033[32mUpdate successful for $REPO_DIR\\033[0m" || echo -e "\\033[31mFailed to update $REPO_DIR\\033[0m"
    COUNT=$((COUNT + 1))
  else
    echo -e "\\033[31mError: Could not navigate to $REPO_DIR\\033[0m"
  fi

  echo ""
done

# Final status message
echo -e "\\n\\033[32mComplete! Processed $COUNT repositories.\\033[0m\\n"
