#!/bin/bash

# Define local download path
mkdir -p /home/ec2-user/received-logs/ec2-logs
mkdir -p /home/ec2-user/received-logs/app/logs

# Download logs from S3
aws s3 cp s3://${BUCKET_NAME}/ec2-logs/cloud-init.log /home/ec2-user/received-logs/ec2-logs/cloud-init.log
aws s3 cp s3://${BUCKET_NAME}/app/logs/app.log /home/ec2-user/received-logs/app/logs/app.log

# Optional: print confirmation
echo "Logs downloaded from S3 at $(date)" >> /home/ec2-user/received-logs/download-status.log
