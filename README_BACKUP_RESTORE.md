# Backup and Restore Plan

## Overview
This repository contains the backup workflow for the Samba live data share.
The current backup approach is designed to protect the live data from ransomware, accidental deletion, and full-disk failure.

## Backup Strategy

### 1. Weekly full backup
A full backup is created once per week.

- Folder naming format: full_YYYY-MM-DD_HHMMSS
- Purpose: provides a full restore point for disaster recovery

### 2. Daily incremental backup
A daily backup is created on the other days.

- Folder naming format: daily_YYYY-MM-DD_HHMMSS
- Purpose: captures daily changes and reduces backup size
- Uses rsync with hard-link based inheritance from the latest snapshot

### 3. Retention policy
The backup location keeps:
- the last 4 full backups
- the last 7 daily backups

Older backups are removed automatically to manage disk usage.

## Backup Location
The backup root is:

- /opt/backup/backup_of_opt_ccpldata_ccplnewdata_latest_version

Each backup run creates a new dated folder inside this location.
The `latest` symlink points to the most recently completed snapshot.

## Restore Procedure

### Full restore after live disk failure
If the live 1 TB data disk fails:
1. Replace or recreate the live disk.
2. Mount the new disk at the correct location.
3. Restore the latest known-good snapshot folder to the live data path.
4. Verify permissions and Samba access.

### Restore after ransomware or accidental deletion
If files are encrypted or deleted:
1. Stop access to the Samba share.
2. Identify the latest known-good backup version.
3. Restore the required files or folders from that backup version.
4. Re-enable access after verification.

## Operational Notes
- The backup script uses a lock to prevent overlapping backup runs.
- Backup logs are written under /home/cce/logs/rsync.
- The latest change report is copied to `latest_changed_files.txt` in the backup root.
- The script sends an email notification if the configured email script exists.

## Ansible Vault password setup for root
When running Ansible as root, configure the vault password environment like this:

```bash
sudo -i
echo 'export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass' >> ~/.bashrc
source ~/.bashrc
```

Then create the password file manually and set its permissions:

```bash
echo "your_vault_password_here" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
```

This keeps the vault password outside the repository and allows Ansible to decrypt encrypted files automatically when the playbook runs.

## Recommended Next Step
For stronger protection against ransomware, keep at least one additional offline or offsite backup copy.
