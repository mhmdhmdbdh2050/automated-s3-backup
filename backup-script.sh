#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_DIR="${SOURCE_DIR:-${SCRIPT_DIR}/source-data}"
BACKUP_DIR="${BACKUP_DIR:-${SCRIPT_DIR}/backups}"
S3_BUCKET="${S3_BUCKET:-}"
S3_PREFIX="${S3_PREFIX:-}"
AWS_REGION="${AWS_REGION:-}"

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

fail() {
  log "ERROR: $*" >&2
  exit 1
}

[[ -d "$SOURCE_DIR" ]] || fail "Source directory does not exist: $SOURCE_DIR"
[[ -n "$S3_BUCKET" ]] || fail 'Set S3_BUCKET to the destination bucket name.'
command -v tar >/dev/null 2>&1 || fail 'tar is required.'
command -v aws >/dev/null 2>&1 || fail 'AWS CLI is required.'

SOURCE_DIR="$(cd -- "$SOURCE_DIR" && pwd -P)"
mkdir -p -- "$BACKUP_DIR"
BACKUP_DIR="$(cd -- "$BACKUP_DIR" && pwd -P)"

case "${BACKUP_DIR}/" in
  "${SOURCE_DIR}/"*) fail 'BACKUP_DIR must not be inside SOURCE_DIR.' ;;
esac

timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
backup_file="$(mktemp "${BACKUP_DIR}/backup-${timestamp}-XXXXXX.tar.gz")"
archive_ready=0
cleanup_partial_archive() {
  if [[ "$archive_ready" -eq 0 ]]; then
    rm -f -- "$backup_file"
  fi
}
trap cleanup_partial_archive EXIT

log "Creating archive from ${SOURCE_DIR}"
tar -C "$SOURCE_DIR" -czf "$backup_file" . || fail 'Archive creation failed.'
[[ -s "$backup_file" ]] || fail 'Archive is empty.'
archive_ready=1

object_name="$(basename -- "$backup_file")"
prefix="${S3_PREFIX#/}"
prefix="${prefix%/}"
if [[ -n "$prefix" ]]; then
  s3_uri="s3://${S3_BUCKET}/${prefix}/${object_name}"
else
  s3_uri="s3://${S3_BUCKET}/${object_name}"
fi

aws_args=(s3 cp --only-show-errors "$backup_file" "$s3_uri")
if [[ -n "$AWS_REGION" ]]; then
  aws_args+=(--region "$AWS_REGION")
fi

log "Uploading archive to ${s3_uri}"
aws "${aws_args[@]}" || fail "Upload failed; the local archive is retained at ${backup_file}."
log "Backup completed: ${backup_file}"
