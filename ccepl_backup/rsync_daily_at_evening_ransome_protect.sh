#!/bin/sh
set -u

BKP_LOC_SRC='/opt/ccpldata/ccplnewdata'
BKP_LOC_DST='/opt/backup/backup_of_opt_ccpldata_ccplnewdata_latest_version'
LOG_DIR='/home/cce/logs/rsync'
RSYNC_EMAIL_FILE='/home/cce/rayo/scripts/github/cceplrsyncmail_ransome.py'
KEEP_DAILY=7
KEEP_FULL=4
LATEST_LINK="$BKP_LOC_DST/latest"
LATEST_CHANGE_REPORT_FILE="$BKP_LOC_DST/latest_changed_files.txt"
FULL_WEEK_MARKER="$BKP_LOC_DST/.last_full_backup_week"
LOCK_FILE="$BKP_LOC_DST/.backup.lock"
CURRENT_WEEK=$(date +%G-%V)
STATUS=0
backup_dir=''
change_report=''
backup_complete=0

send_email_report() {
  if [ -f "$RSYNC_EMAIL_FILE" ]; then
    python3 "$RSYNC_EMAIL_FILE" || echo "WARNING: email report script failed."
  fi
}

finish() {
  STATUS=$?
  if [ "$STATUS" -eq 0 ]; then
    BACKUP_STATUS=SUCCESS
    echo "Backup completed at: $(date)"
  else
    BACKUP_STATUS=FAILED
    echo "Backup failed at: $(date)"
    if [ -n "$backup_dir" ] && [ "$backup_complete" -eq 0 ] && [ -d "$backup_dir" ]; then
      echo "Removing incomplete backup snapshot: $backup_dir"
      rm -rf "$backup_dir"
    fi
  fi
  export BACKUP_STATUS
  echo "Log file: $log_file"
  send_email_report
  exit "$STATUS"
}

write_full_change_report() {
  report_file=$1

  {
    printf 'Backup type: FULL\n'
    printf 'Backup time: %s\n' "$(date)"
    printf 'Source: %s\n' "$BKP_LOC_SRC"
    printf '\n'
    printf 'All files are included in this full backup.\n'
  } > "$report_file"
}

write_daily_change_report() {
  previous_backup=$1
  current_backup=$2
  report_file=$3
  tmp_changed="${report_file}.changed"

  : > "$tmp_changed"

  {
    printf 'Backup type: DAILY_INCREMENTAL\n'
    printf 'Backup time: %s\n' "$(date)"
    printf 'Source: %s\n' "$BKP_LOC_SRC"
    printf 'Previous backup: %s\n' "$previous_backup"
    printf 'Current backup: %s\n' "$current_backup"
    printf '\n'
    printf 'Incremental file list:\n'
  } > "$report_file"

  (
    cd "$current_backup" || exit 1
    find . \( -type f -o -type l \) -print | sort
  ) | while IFS= read -r rel_path; do
    old_path="$previous_backup/$rel_path"
    new_path="$current_backup/$rel_path"

    if [ ! -e "$old_path" ] && [ ! -L "$old_path" ]; then
      printf 'ADDED %s\n' "${rel_path#./}" >> "$tmp_changed"
    elif [ -L "$old_path" ] || [ -L "$new_path" ]; then
      if [ ! -L "$old_path" ] || [ ! -L "$new_path" ] || [ "$(readlink "$old_path")" != "$(readlink "$new_path")" ]; then
        printf 'MODIFIED %s\n' "${rel_path#./}" >> "$tmp_changed"
      fi
    elif [ ! "$old_path" -ef "$new_path" ]; then
      printf 'MODIFIED %s\n' "${rel_path#./}" >> "$tmp_changed"
    fi
  done

  (
    cd "$previous_backup" || exit 1
    find . \( -type f -o -type l \) -print | sort
  ) | while IFS= read -r rel_path; do
    new_path="$current_backup/$rel_path"

    if [ ! -e "$new_path" ] && [ ! -L "$new_path" ]; then
      printf 'DELETED %s\n' "${rel_path#./}" >> "$tmp_changed"
    fi
  done

  if [ -s "$tmp_changed" ]; then
    cat "$tmp_changed" >> "$report_file"
  else
    printf 'No changes detected.\n' >> "$report_file"
  fi

  rm -f "$tmp_changed"
}

latest_backup_dir() {
  find "$BKP_LOC_DST" -maxdepth 1 -mindepth 1 -type d \( -name 'full_*' -o -name 'daily_*' \) \
    -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d ' ' -f 2-
}

create_full_backup() {
  backup_name="full_$(date +%F_%H%M%S)"
  backup_dir="$BKP_LOC_DST/$backup_name"
  change_report="$backup_dir/changed_files.txt"

  echo "Creating full backup: $backup_dir"
  mkdir -p "$backup_dir"
  rsync -aHAX --numeric-ids --delete "$BKP_LOC_SRC/" "$backup_dir/"
  write_full_change_report "$change_report"
  printf '%s\n' "$CURRENT_WEEK" > "$FULL_WEEK_MARKER"
  backup_complete=1
}

create_daily_backup() {
  previous_backup=$1
  backup_name="daily_$(date +%F_%H%M%S)"
  backup_dir="$BKP_LOC_DST/$backup_name"
  change_report="$backup_dir/changed_files.txt"

  echo "Creating daily incremental backup: $backup_dir"
  echo "Using previous snapshot for link-dest: $previous_backup"
  mkdir -p "$backup_dir"
  rsync -aHAX --numeric-ids --delete --link-dest="$previous_backup" "$BKP_LOC_SRC/" "$backup_dir/"
  write_daily_change_report "$previous_backup" "$backup_dir" "$change_report"
  backup_complete=1
}

update_latest_links() {
  rm -f "$LATEST_LINK" "$LATEST_CHANGE_REPORT_FILE"
  ln -s "$backup_dir" "$LATEST_LINK"
  if [ -f "$change_report" ]; then
    cp "$change_report" "$LATEST_CHANGE_REPORT_FILE"
  else
    : > "$LATEST_CHANGE_REPORT_FILE"
  fi

  echo "Change report for this backup: $change_report"
}

prune_backups() {
  full_dirs=$(find "$BKP_LOC_DST" -maxdepth 1 -mindepth 1 -type d -name 'full_*' | sort)
  full_count=$(printf '%s\n' "$full_dirs" | grep -c . || true)
  if [ "$full_count" -gt "$KEEP_FULL" ]; then
    delete_count=$((full_count - KEEP_FULL))
    printf '%s\n' "$full_dirs" | head -n "$delete_count" | while IFS= read -r old_dir; do
      echo "Pruning old full backup: $old_dir"
      rm -rf "$old_dir"
    done
  fi

  daily_dirs=$(find "$BKP_LOC_DST" -maxdepth 1 -mindepth 1 -type d -name 'daily_*' | sort)
  daily_count=$(printf '%s\n' "$daily_dirs" | grep -c . || true)
  if [ "$daily_count" -gt "$KEEP_DAILY" ]; then
    delete_count=$((daily_count - KEEP_DAILY))
    printf '%s\n' "$daily_dirs" | head -n "$delete_count" | while IFS= read -r old_dir; do
      echo "Pruning old daily backup: $old_dir"
      rm -rf "$old_dir"
    done
  fi
}

mkdir -p "$BKP_LOC_DST" "$LOG_DIR"
starttime=$(date +'%Y-%m-%d_%H%M%S')
log_file="$LOG_DIR/rsync_ransomware_protect_${starttime}.log"

exec >>"$log_file" 2>&1

if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    echo "Another backup is already running."
    exit 0
  fi
else
  running_count=$(ps -ef | grep "rsync .*${BKP_LOC_SRC}" | grep -v grep | wc -l | tr -d ' ')
  if [ "$running_count" -gt 0 ]; then
    echo "Another rsync backup is already running."
    exit 0
  fi
fi

trap finish EXIT
set -e

echo "Backup Source Location: $BKP_LOC_SRC"
echo "Backup Destination Location: $BKP_LOC_DST"
echo "Starting backup at: $(date)"

last_full_week=''
if [ -f "$FULL_WEEK_MARKER" ]; then
  last_full_week=$(cat "$FULL_WEEK_MARKER" 2>/dev/null || true)
fi

latest_backup=$(latest_backup_dir)

if [ -z "$latest_backup" ]; then
  echo "No backup found yet. Creating a full backup first."
  create_full_backup
elif [ "$(date +%u)" -eq 7 ] && [ "$last_full_week" != "$CURRENT_WEEK" ]; then
  echo "Weekly full backup is due for week $CURRENT_WEEK."
  create_full_backup
else
  if [ "$(date +%u)" -eq 7 ]; then
    echo "Weekly full backup already created for week $CURRENT_WEEK. Creating daily incremental backup instead."
  fi
  create_daily_backup "$latest_backup"
fi

update_latest_links
prune_backups
