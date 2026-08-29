# Rsync Replication Setup

This script supports syncing the same directory in both directions:

- Server1 -> Server2
- Server2 -> Server1

It is designed for exact directory mirroring using rsync with `--delete` and `--checksum`.

## Script location

- `ubuntu-local-setup/roles/home_ubuntu_setup/files/rsync_replication_daily.sh`

## Basic usage

### 1) Server1 to Server2
Run this on server2:

```bash
sudo ./rsync_replication_daily.sh \
  cce@192.168.10.239:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/ \
  /opt/ccpldata/ccplnewdata/CCEPL_SERVER/
```

### 2) Server2 to Server1
Run this on server1:

```bash
sudo ./rsync_replication_daily.sh \
  /opt/ccpldata/ccplnewdata/CCEPL_SERVER/ \
  cce@192.168.10.219:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/
```

## Dry run

Always test before actual sync:

```bash
sudo DRY_RUN=true ./rsync_replication_daily.sh \
  cce@192.168.10.239:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/ \
  /opt/ccpldata/ccplnewdata/CCEPL_SERVER/
```

## Environment variables

You can also set source and destination using environment variables:

```bash
sudo RSYNC_SOURCE='cce@192.168.10.239:/opt/ccpldata/ccplnewdata/CCEPL_SERVER/' \
     RSYNC_DEST='/opt/ccpldata/ccplnewdata/CCEPL_SERVER/' \
     ./rsync_replication_daily.sh
```

## Notes

- `--delete` removes files on the destination that do not exist on the source.
- `--checksum` compares content to ensure exact matching.
- Logs are saved under `/home/cce/logs/rsync/`.
- SSH passwordless login is recommended between servers.

## SSH setup example

On the destination server, run:

```bash
ssh-keygen
ssh-copy-id cce@192.168.10.239
```

Then test:

```bash
ssh cce@192.168.10.239
```
