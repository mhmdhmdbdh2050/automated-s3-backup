# Automated VM backup to Amazon S3

A small Bash learning project that archives a local directory and uploads each archive to an S3 bucket. The script keeps a local copy so an upload failure does not discard the backup.

## Requirements

- Linux or WSL with Bash, GNU `tar`, `date`, and `mktemp`.
- AWS CLI v2 configured with an AWS profile, an instance role, or another supported credential provider. Do not put access keys in this repository or in the script.
- An S3 bucket that you own and permission to upload objects to the chosen prefix.

## Quick start

```bash
git clone https://github.com/mhmdhmdbdh2050/automated-s3-backup.git
cd automated-s3-backup
chmod +x backup-script.sh

export S3_BUCKET='your-backup-bucket'
export S3_PREFIX='vm-backups'
export AWS_REGION='us-east-1'
# Optional: select a profile configured outside this repository.
export AWS_PROFILE='backup-role'
./backup-script.sh
```

The included `source-data/` directory is only a sample. Point `SOURCE_DIR` at the directory you intend to protect and `BACKUP_DIR` at a separate local disk location:

```bash
export SOURCE_DIR='/path/to/data'
export BACKUP_DIR='/path/to/local-backups'
./backup-script.sh
```

`BACKUP_DIR` cannot be inside `SOURCE_DIR`; this prevents the script from archiving its own previous output. A successful run creates a uniquely named UTC `.tar.gz` file locally, then uploads it to `s3://$S3_BUCKET/$S3_PREFIX/`. If the upload fails, the completed local archive is kept for retry. The script exits non-zero on invalid configuration or a failed archive/upload.

## Scheduling with cron

Test the command manually before scheduling it. Cron runs with a limited environment, so pass non-secret settings explicitly or use a wrapper. Store AWS credentials in the normal AWS credential provider (for example, a profile in the running user's `~/.aws/` directory or an instance role), never in the crontab or this repository.

Example hourly schedule with non-secret settings in the crontab. The `backup-role` profile must be configured for the same operating-system user that owns this cron job; a VM instance role is another option:

```cron
0 * * * * S3_BUCKET='your-backup-bucket' S3_PREFIX='vm-backups' AWS_REGION='us-east-1' AWS_PROFILE='backup-role' /path/to/automated-s3-backup/backup-script.sh >> /var/log/s3-backup.log 2>&1
```

Choose the interval based on the recovery-point objective and the amount of data. The old five-minute schedule could create unnecessary storage and request costs.

## IAM and S3 safety

- Use a dedicated IAM role or user with permissions scoped to the chosen bucket prefix. `s3:PutObject` is required; large uploads may also need multipart permissions such as `s3:AbortMultipartUpload` and `s3:ListMultipartUploadParts`.
- Enable S3 Block Public Access, encryption at rest, versioning, and an appropriate lifecycle/retention policy on the bucket.
- Keep AWS credentials outside Git. `.gitignore` excludes local backups, logs, environment files, and AWS credential files, but it is not a substitute for reviewing commits before pushing.
- S3 upload is not proof of recoverability. Periodically download an archive into a disposable location, run `tar -tzf`, and test restoring a sample file.
- Backups may contain personal or confidential data. Protect the local backup directory and the S3 bucket accordingly.
- This script does not delete old local or S3 archives. Plan and test separate retention policies so frequent runs do not fill the local disk or create unbounded S3 storage costs.

## Local verification

The test suite uses a mock AWS CLI and does not contact AWS or require credentials:

```bash
bash -n backup-script.sh scripts/test-backup.sh
bash scripts/test-backup.sh
```

## Configuration

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `S3_BUCKET` | Yes | — | Destination bucket name |
| `SOURCE_DIR` | No | `source-data/` beside the script | Files to archive |
| `BACKUP_DIR` | No | `backups/` beside the script | Local archive destination |
| `S3_PREFIX` | No | Bucket root | Destination key prefix |
| `AWS_REGION` | No | AWS CLI/profile default | S3 request region |
| `AWS_PROFILE` | No | `default` profile / credential chain | AWS CLI profile to use |

## Project structure

```text
.
├── backup-script.sh
├── source-data/       # disposable example input
├── backups/           # generated local archives; ignored by Git
└── README.md
```
