#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
cleanup() {
  rm -rf -- "$TEST_DIR"
}
trap cleanup EXIT

mkdir -p "$TEST_DIR/bin" "$TEST_DIR/source" "$TEST_DIR/backups" "$TEST_DIR/nested"
printf 'sample backup content\n' > "$TEST_DIR/source/sample.txt"

cat > "$TEST_DIR/bin/aws" <<'MOCK_AWS'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' "$@" > "$AWS_ARGS_FILE"
if [[ "${AWS_STUB_FAIL:-0}" == '1' ]]; then
  exit 7
fi
MOCK_AWS
chmod +x "$TEST_DIR/bin/aws"

export PATH="$TEST_DIR/bin:$PATH"
export AWS_ARGS_FILE="$TEST_DIR/aws-args.txt"
export SOURCE_DIR="$TEST_DIR/source"
export BACKUP_DIR="$TEST_DIR/backups"
export S3_BUCKET='test-backup-bucket'
export S3_PREFIX='/portfolio/test/'
export AWS_REGION='us-east-1'

"$SCRIPT_DIR/backup-script.sh"
mapfile -t archives < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'backup-*.tar.gz' -print)
[[ "${#archives[@]}" -eq 1 ]] || { echo 'Expected exactly one local archive.' >&2; exit 1; }
tar -tzf "${archives[0]}" | grep -Fxq './sample.txt' || {
  echo 'Archive does not contain the sample file.' >&2
  exit 1
}
grep -Fxq 's3://test-backup-bucket/portfolio/test/'"$(basename -- "${archives[0]}")" "$AWS_ARGS_FILE" || {
  echo 'Upload destination did not match the configured bucket and prefix.' >&2
  exit 1
}
grep -Fxq -- '--region' "$AWS_ARGS_FILE" || { echo 'AWS region was not passed.' >&2; exit 1; }

if S3_BUCKET='' "$SCRIPT_DIR/backup-script.sh" >/dev/null 2>&1; then
  echo 'Expected a missing bucket to fail.' >&2
  exit 1
fi

if SOURCE_DIR="$TEST_DIR" BACKUP_DIR="$TEST_DIR/nested" "$SCRIPT_DIR/backup-script.sh" >/dev/null 2>&1; then
  echo 'Expected a backup directory nested in the source to fail.' >&2
  exit 1
fi

mkdir -p "$TEST_DIR/upload-failure-backups"
if BACKUP_DIR="$TEST_DIR/upload-failure-backups" AWS_STUB_FAIL=1 "$SCRIPT_DIR/backup-script.sh" >/dev/null 2>&1; then
  echo 'Expected a failed upload to return non-zero.' >&2
  exit 1
fi
mapfile -t retained < <(find "$TEST_DIR/upload-failure-backups" -maxdepth 1 -type f -name 'backup-*.tar.gz' -print)
[[ "${#retained[@]}" -eq 1 && -s "${retained[0]}" ]] || {
  echo 'Expected the completed archive to be retained after upload failure.' >&2
  exit 1
}

echo 'All backup script checks passed.'
