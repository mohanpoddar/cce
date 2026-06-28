#!/bin/sh
set -eu

BKP_LOC_SRC='/opt/ccpldata/ccplnewdata'
BKP_LOC_DST='/opt/backup/backup_of_opt_ccpldata_ccplnewdata_latest_version'
LOG_DIR='/home/cce/logs/rsync'
RSYNC_EMAIL_FILE='/home/cce/rayo/scripts/github/cce/ubuntu-local-setup/roles/home_ubuntu_setup/files/cceplrsyncmail.py'
KEEP_DAILY=7
KEEP_FULL=4
LATEST_LINK="$BKP_LOC_DST/latest"
LATEST_CHANGE_REPORT_FILE="$BKP_LOC_DST/latest_changed_files.txt"
FULL_WEEK_MARKER="$BKP_LOC_DST/.last_full_backup_week"
CURRENT_WEEK=$(date +%G-%V)

mkdir -p "$BKP_LOC_DST" "$LOG_DIR"

PS1=$(ps -ef | egrep "rsync .*${BKP_LOC_SRC}" | grep -v grep | wc -l | tr -d ' ')
starttime=$(date +'%Y-%m-%d_%H%M%S')
log_file="$LOG_DIR/rsync_${starttime}.log"

if [ "$PS1" -gt 1 ]; then
  echo "Rsync is already running."
  exit 0
fi

exec >>"$log_file" 2>&1

echo "Backup Source Location: $BKP_LOC_SRC"
echo "Backup Destination Location: $BKP_LOC_DST"
echo "Starting backup at: $(date)"

if [ "$(date +%u)" -eq 7 ]; then
  last_full_week=""
  if [ -f "$FULL_WEEK_MARKER" ]; then
    last_full_week=$(cat "$FULL_WEEK_MARKER" 2>/dev/null || true)
  fi

  if [ "$last_full_week" = "$CURRENT_WEEK" ]; then
    echo "Weekly full backup already created for week $CURRENT_WEEK. Creating daily incremental backup instead."
    backup_name="daily_$(date +%F_%H%M%S)"
    backup_dir="$BKP_LOC_DST/$backup_name"
    latest_backup=""
    if [ -d "$BKP_LOC_DST" ]; then
      latest_backup=$(find "$BKP_LOC_DST" -maxdepth 1 -mindepth 1 -type d \( -name 'full_*' -o -name 'daily_*' \) | sort | tail -n 1)
    fi

    if [ -z "$latest_backup" ]; then
      echo "No backup found yet. Creating a full backup first."
      backup_name="full_$(date +%F_%H%M%S)"
      backup_dir="$BKP_LOC_DST/$backup_name"
      mkdir -p "$backup_dir"
      change_report="$backup_dir/changed_files.txt"
      : > "$change_report"
      rsync -aHAX --numeric-ids --delete "$BKP_LOC_SRC/" "$backup_dir/"
      printf 'Full backup created; all files included.\n' > "$change_report"
      printf '%s\n' "$CURRENT_WEEK" > "$FULL_WEEK_MARKER"
    else
      echo "Creating daily incremental backup: $backup_dir"
      mkdir -p "$backup_dir"
      change_report="$backup_dir/changed_files.txt"
      : > "$change_report"
      rsync -aHAX --numeric-ids --delete --link-dest="$latest_backup" \
        --itemize-changes --out-format='%i %n' \
        "$BKP_LOC_SRC/" "$backup_dir/" > "$change_report" 2>&1
    fi
  else
    backup_name="full_$(date +%F_%H%M%S)"
    backup_dir="$BKP_LOC_DST/$backup_name"
    echo "Creating weekly full backup: $backup_dir"
    mkdir -p "$backup_dir"
    change_report="$backup_dir/changed_files.txt"
    : > "$change_report"
    rsync -aHAX --numeric-ids --delete "$BKP_LOC_SRC/" "$backup_dir/"
    printf 'Full backup created; all files included.\n' > "$change_report"
    printf '%s\n' "$CURRENT_WEEK" > "$FULL_WEEK_MARKER"
  fi
else
  backup_name="daily_$(date +%F_%H%M%S)"
  backup_dir="$BKP_LOC_DST/$backup_name"
  latest_backup=""
  if [ -d "$BKP_LOC_DST" ]; then
    latest_backup=$(find "$BKP_LOC_DST" -maxdepth 1 -mindepth 1 -type d \( -name 'full_*' -o -name 'daily_*' \) | sort | tail -n 1)
  fi

  if [ -z "$latest_backup" ]; then
    echo "No backup found yet. Creating a full backup first."
    backup_name="full_$(date +%F_%H%M%S)"
    backup_dir="$BKP_LOC_DST/$backup_name"
    mkdir -p "$backup_dir"
    change_report="$backup_dir/changed_files.txt"
    : > "$change_report"
    rsync -aHAX --numeric-ids --delete "$BKP_LOC_SRC/" "$backup_dir/"
    printf 'Full backup created; all files included.\n' > "$change_report"
    printf '%s\n' "$CURRENT_WEEK" > "$FULL_WEEK_MARKER"
  else
    echo "Creating daily incremental backup: $backup_dir"
    mkdir -p "$backup_dir"
    change_report="$backup_dir/changed_files.txt"
    : > "$change_report"
    rsync -aHAX --numeric-ids --delete --link-dest="$latest_backup" \
      --itemize-changes --out-format='%i %n' \
      "$BKP_LOC_SRC/" "$backup_dir/" > "$change_report" 2>&1
  fi
fi

rm -f "$LATEST_LINK" "$LATEST_CHANGE_REPORT_FILE"
ln -s "$backup_dir" "$LATEST_LINK"
if [ -f "$change_report" ]; then
  cp "$change_report" "$LATEST_CHANGE_REPORT_FILE"
else
  : > "$LATEST_CHANGE_REPORT_FILE"
fi

echo "Change report for this backup: $change_report"

full_dirs=$(find "$BKP_LOC_DST" -maxdepth 1 -mindepth 1 -type d -name 'full_*' | sort)
full_count=$(printf '%s
' "$full_dirs" | grep -c . || true)
if [ "$full_count" -gt "$KEEP_FULL" ]; then
  delete_count=$((full_count - KEEP_FULL))
  printf '%s
' "$full_dirs" | head -n "$delete_count" | while read -r old_dir; do
    rm -rf "$old_dir"
  done
fi

daily_dirs=$(find "$BKP_LOC_DST" -maxdepth 1 -mindepth 1 -type d -name 'daily_*' | sort)
daily_count=$(printf '%s
' "$daily_dirs" | grep -c . || true)
if [ "$daily_count" -gt "$KEEP_DAILY" ]; then
  delete_count=$((daily_count - KEEP_DAILY))
  printf '%s
' "$daily_dirs" | head -n "$delete_count" | while read -r old_dir; do
    rm -rf "$old_dir"
  done
fi

echo "Backup completed at: $(date)"

echo "Log file: $log_file"

if [ -f "$RSYNC_EMAIL_FILE" ]; then
  python3 "$RSYNC_EMAIL_FILE"
fi
