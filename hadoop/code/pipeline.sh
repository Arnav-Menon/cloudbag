#!/bin/bash

DATE=$(date '+%Y%m%d')
# Set up logging
LOG_FILE="/home/ubuntu/logs/pipeline_${DATE}.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "===== Pipeline started at $(date) ====="

BASE_DIR="/home/ubuntu/code"
HADOOP_HOME="/usr/local/hadoop"
HDFS_DIR="/databag-dir"
FILES_DIR="$BASE_DIR/files"
TOKEN_SCRIPT="$BASE_DIR/token.sh"
PYTHON_PATH="/usr/bin/python3"
PYTHON_SCRIPT="$BASE_DIR/fetch_data.py"
DATA_FILE="$FILES_DIR/data.jsonl"
EMAIL_SCRIPT="$BASE_DIR/send_email.py"

# Function to log errors and exit
log_error() {
    echo "[ERROR] $1"
    exit 1
}

# Exit on any error
set -e

# Step 1: Get new token
echo "Step 1: Retrieving new token..."
/bin/bash "$TOKEN_SCRIPT" || log_error "Failed to retrieve token."

# Step 2: Make Python request to API
echo "Step 2: Running Python script ($PYTHON_SCRIPT)..."
"$PYTHON_PATH" "$PYTHON_SCRIPT" || log_error "Failed to run Python script."

# Step 3: Push data to HDFS
HDFS_FILE="$HDFS_DIR/data_${DATE}.jsonl"

echo "Step 3: Uploading data to HDFS: $HDFS_FILE"
/"$HADOOP_HOME/bin/hdfs" dfs -put "$DATA_FILE" "$HDFS_FILE" || log_error "Failed to push data to HDFS."

# Step 4: Run Hadoop MapReduce job
HDFS_OUTPUT="$HDFS_DIR/output_${DATE}"
echo "Step 4: Running Hadoop MapReduce job with output: $HDFS_OUTPUT"

"$HADOOP_HOME/bin/hadoop" jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
    -input "$HDFS_FILE" \
    -output "$HDFS_OUTPUT" \
    -mapper "$BASE_DIR/mapper.py" \
    -reducer "$BASE_DIR/reducer.py" \
    -file "$BASE_DIR/mapper.py" \
    -file "$BASE_DIR/reducer.py" || log_error "Failed to run Hadoop job."

# Step 5: Retrieve output from HDFS
LOCAL_OUTPUT="$FILES_DIR/output_local_${DATE}"
echo "Step 5: Fetching output from HDFS to $LOCAL_OUTPUT"

"$HADOOP_HOME/bin/hdfs" dfs -get "$HDFS_OUTPUT" "$LOCAL_OUTPUT" || log_error "Failed to fetch output from HDFS."

# Step 6: Send email
echo "Step 6: Sending email with report..."
"$PYTHON_PATH" "$EMAIL_SCRIPT" || log_error "Failed to send email."

echo "===== Pipeline completed successfully at $(date) ====="