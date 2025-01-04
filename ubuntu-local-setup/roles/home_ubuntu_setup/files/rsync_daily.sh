#!/bin/bash
#PS1=`ps -ef | grep rsync | grep -v grep | wc -l`
PS1=`ps -ef | egrep "rsync -avP /opt/ccpldata/ccplnewdata" | grep -v grep | wc -l`
BKP_LOC_SRC='/opt/ccpldata/ccplnewdata'
#BKP_LOC_DST='/opt/backup/backup_of_opt_ccpldata_ccplnewdata_20-12-2024/'
BKP_LOC_DST='/opt/backup/backup_of_opt_ccpldata_ccplnewdata_latest/'
RSYNC_EMAIL_FILE='/home/cce/rayo/scripts/github/cce/ubuntu-local-setup/roles/home_ubuntu_setup/files/cceplrsyncmail.py'

echo "Backup Source Location: $BKP_LOC_SRC"
echo "Backup Destination Location: $BKP_LOC_DST"

echo "Number of rsync process: $PS1"


ccersync () {

	if [ $PS1 -gt 1 ];
	then
          echo "Rsync is running."
        else
          starttime=$(date +'%d-%m-%Y-%H%M%S')
	  echo "TASK STARTS AT : $(date)" >> /home/cce/logs/rsync/rsync_cron_$starttime.log
	  echo "START rsync at : $(date)" >> /home/cce/logs/rsync/rsync_cron_$starttime.log
	  echo "BEFORE - Check for rsync backup log: /home/cce/logs/rsync/rsync_in_backup_location_date_20-12-2024_actual_$starttime.log" >> /home/cce/logs/rsync/rsync_cron_$starttime.log

          rsync -avP $BKP_LOC_SRC $BKP_LOC_DST >> /home/cce/logs/rsync/rsync_in_backup_location_date_20-12-2024_actual_$starttime.log 2>&1

	  echo "AFTER - Check for rsync backup log: /home/cce/logs/rsync/rsync_in_backup_location_date_20-12-2024_actual_$starttime.log" >> /home/cce/logs/rsync/rsync_cron_$starttime.log
	  echo "END rsync at : $(date)" >> /home/cce/logs/rsync/rsync_cron_$starttime.log
	  echo "Rysnc is finished : $(date)" >> /home/cce/logs/rsync/rsync_cron_$starttime.log
	  echo "TASK ENDS AT : $(date)" >> /home/cce/logs/rsync/rsync_cron_$starttime.log
	  python3 $RSYNC_EMAIL_FILE
	  
        fi
}

ccersync
