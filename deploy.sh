#!/bin/bash

########
# Author: Your Name
# Date: 2025-02-04
#
# Version: v1.2
#
# Static Site Server Deployment Script
#
# This script uses scp to sync your static site from your local machine to a remote server.
########

# Enable debug mode
set -x

# Change to script directory
cd "$(dirname "$0")" || exit

# Remote server details
REMOTE_USER="ec2-user"
REMOTE_HOST="44.204.60.96"
REMOTE_DIR="/usr/share/nginx/html"

# SSH key path
SSH_KEY="$HOME/.ssh/my_second_key"

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

# Test SSH connection first
echo "Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_USER@$REMOTE_HOST" echo "SSH connection successful"; then
    echo "Error: SSH connection failed. Please check your SSH key and server configuration."
    exit 1
fi

# Create a temporary directory on the remote server
echo "Creating temporary directory on remote server..."
TEMP_DIR="/tmp/static-site-$(date +%s)"
if ! ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $TEMP_DIR"; then
    echo "Error: Failed to create temporary directory"
    exit 1
fi

# Copy files to temporary directory
echo "Copying files to remote server..."
if ! scp -i "$SSH_KEY" -r ./* "$REMOTE_USER@$REMOTE_HOST:$TEMP_DIR/"; then
    echo "Error: Failed to copy files"
    ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "rm -rf $TEMP_DIR"
    exit 1
fi

# Move files to final location
echo "Moving files to final location..."
if ! ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "sudo rm -rf $REMOTE_DIR/* && sudo cp -r $TEMP_DIR/* $REMOTE_DIR/ && sudo chown -R nginx:nginx $REMOTE_DIR && sudo chmod -R 755 $REMOTE_DIR && rm -rf $TEMP_DIR"; then
    echo "Error: Failed to move files to final location"
    ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "rm -rf $TEMP_DIR"
    exit 1
fi

echo "Deployment completed successfully!"
