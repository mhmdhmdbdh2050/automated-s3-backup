# Automated VM Backup and Replication to AWS S3

A Bash-based automation project that creates compressed backups of a local directory and automatically uploads them to an Amazon S3 bucket.

## Features

- Creates compressed `.tar.gz` backups
- Adds a timestamp to every backup file
- Uploads backups automatically to Amazon S3
- Uses AWS CLI for S3 integration
- Runs automatically using Cron
- Executes every 5 minutes
- Stores execution output and errors in a log file

## Technologies Used

- Linux
- Bash Scripting
- Amazon S3
- IAM
- AWS CLI
- Cron
- Git
- GitHub

## Project Structure

```text
backup-project/
├── backup-script.sh
├── source-data/
│   └── file1.txt
├── backups/
├── backup.log
├── README.md
└── .gitignore
```

## How It Works

1. The Bash script takes the files from the source directory.
2. The files are compressed into a `.tar.gz` backup.
3. A timestamp is added to the backup filename.
4. The backup file is stored locally in the `backups/` directory.
5. AWS CLI uploads the backup file to an Amazon S3 bucket.
6. Cron automatically runs the script every 5 minutes.

## Cron Job

The following Cron Job runs the backup script every 5 minutes:

```bash
*/5 * * * * /home/ubuntu/backup-project/backup-script.sh >> /home/ubuntu/backup-project/backup.log 2>&1
```

## Logging

The output and errors from the backup script are stored in:

```text
/home/ubuntu/backup-project/backup.log
```

## Security

Sensitive files and generated files are excluded from GitHub using `.gitignore`.

## Project Goal

This project demonstrates how Bash scripting, Cron scheduling, AWS CLI, IAM permissions, and Amazon S3 can be combined to automate VM data backups and cloud replication.

## Author

Mohamed Ahmed Abdo

