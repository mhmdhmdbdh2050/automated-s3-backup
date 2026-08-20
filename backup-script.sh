#!/bin/bash

SOURCE_DIR="/home/ubuntu/backup-project/source-date"

BACKUP_DIR="/home/ubuntu/backup-project/backups"

TIMESTAMP=$(date + %Y-%M-%D_%H_%M_%S)

BACKUP_FILE="$BACKUP_DIR/backup-$TIMESTAMP.tar.gz"

tar -czf "$BACKUP_FILE" "$SOURCE_DIR"
echo "Backup created successfully : $BACKUP_FILE"
S3_BUCKET="s3-abdo-bash-course"
aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET"
echo "Backup uploaded successfully to S3: $S3_BUCKET"
