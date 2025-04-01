#!/bin/bash

# Set variables
SOURCE_FILE="ubuntu@10.10.0.146:/home/ubuntu/files/adminToken.txt"
DEST_USER="ubuntu"
DEST_HOST="127.0.0.1"
DEST_PATH="/home/ubuntu/code/files/"
PRIVATE_KEY_PATH="/home/ubuntu/.ssh/id_rsa_scp"  # Path to the private key

echo "Source file: $SOURCE_FILE"
echo "Destination: $DEST_USER@$DEST_HOST:$DEST_PATH"
echo "Private key: $PRIVATE_KEY_PATH"

# Copy the file using SCP with the specified private key
scp -i $PRIVATE_KEY_PATH $SOURCE_FILE $DEST_PATH