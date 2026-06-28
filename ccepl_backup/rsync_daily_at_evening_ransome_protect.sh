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
    cd "$current_backup"
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
    cd "$previous_backup"
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
      rsync -aHAX --numeric-ids --delete "$BKP_LOC_SRC/" "$backup_dir/"
      write_full_change_report "$change_report"
      printf '%s\n' "$CURRENT_WEEK" > "$FULL_WEEK_MARKER"
    else
      echo "Creating daily incremental backup: $backup_dir"
      mkdir -p "$backup_dir"
      change_report="$backup_dir/changed_files.txt"
      rsync -aHAX --numeric-ids --delete --link-dest="$latest_backup" "$BKP_LOC_SRC/" "$backup_dir/"
      write_daily_change_report "$latest_backup" "$backup_dir" "$change_report"
    fi
  else
    backup_name="full_$(date +%F_%H%M%S)"
    backup_dir="$BKP_LOC_DST/$backup_name"
    echo "Creating weekly full backup: $backup_dir"
    mkdir -p "$backup_dir"
    change_report="$backup_dir/changed_files.txt"
    rsync -aHAX --numeric-ids --delete "$BKP_LOC_SRC/" "$backup_dir/"
    write_full_change_report "$change_report"
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
    rsync -aHAX --numeric-ids --delete "$BKP_LOC_SRC/" "$backup_dir/"
    write_full_change_report "$change_report"
    printf '%s\n' "$CURRENT_WEEK" > "$FULL_WEEK_MARKER"
  else
    echo "Creating daily incremental backup: $backup_dir"
    mkdir -p "$backup_dir"
    change_report="$backup_dir/changed_files.txt"
    rsync -aHAX --numeric-ids --delete --link-dest="$latest_backup" "$BKP_LOC_SRC/" "$backup_dir/"
    write_daily_change_report "$latest_backup" "$backup_dir" "$change_report"
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
