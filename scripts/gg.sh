
#!/bin/bash

# Check if the argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <commit-message>"
  exit 1
fi

# Split the argument into type and message
COMMIT_TYPE=$(echo $1 | awk '{print $1}')
COMMIT_MESSAGE=$(echo $1 | cut -d' ' -f2-)

# Construct the commit message
FULL_COMMIT_MESSAGE="$COMMIT_TYPE: $COMMIT_MESSAGE"

# Run the Git commands
git add .
git commit -am "$FULL_COMMIT_MESSAGE"
git push
