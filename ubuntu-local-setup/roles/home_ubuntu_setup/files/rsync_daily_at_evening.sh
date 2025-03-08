#!/bin/bash

# Set DC variable based on hostname
if [ "$(hostname)" = "av-pc" ]; then
    DC="GreaterNoida"
    PS1=`ps -ef | egrep "rsync -avP /opt/ccpldata/ccplnewdata" | grep -v grep | wc -l`
    BKP_LOC_SRC='/opt/ccpldata/ccplnewdata'
    BKP_LOC_DST='/opt/backup/backup_of_opt_ccpldata_ccplnewdata_latest/'
    RSYNC_EMAIL_FILE='/home/cce/rayo/scripts/github/cce/ubuntu-local-setup/roles/home_ubuntu_setup/files/cceplrsyncmail.py'

elif [ "$(hostname)" = "503S" ]; then
    DC="Vashundhara"
    PS1=`ps -ef | egrep "rsync -avP /opt/ccepldata/cceplserver" | grep -v grep | wc -l`
    BKP_LOC_SRC='/opt/ccepldata/cceplserver'
    BKP_LOC_DST='/opt/backup/backup_of_opt_ccpldata_cceplserver_latest/'
    RSYNC_EMAIL_FILE='/home/cce/rayo/scripts/github/cce/ubuntu-local-setup/roles/home_ubuntu_setup/files/cceplrsyncmail.py'

elif [ "$(hostname)" = "mylearnersepoint" ]; then
    DC="TESTLEPOINT"
    PS1=`ps -ef | egrep "rsync -avP /opt/ccpldata/mylearnersepoint" | grep -v grep | wc -l`
    BKP_LOC_SRC='/opt/ccpldata/mylearnersepoint'
    BKP_LOC_DST='/opt/backup/mylearnersepoint/'
    RSYNC_EMAIL_FILE='/home/cce/rayo/scripts/github/cce/ubuntu-local-setup/roles/home_ubuntu_setup/files/cceplrsyncmail.py'

else
    DC="UNKNOWN"
fi

echo "Hostname: $(hostname)"
echo "Number of rsync process: $PS1"
echo "Host Location: $DC"
echo "Backup Source Location: $BKP_LOC_SRC"
echo "Backup Destination Location: $BKP_LOC_DST"
echo "Rsync Email File: $RSYNC_EMAIL_FILE"


# #PS1=`ps -ef | grep rsync | grep -v grep | wc -l`
# PS1=`ps -ef | egrep "rsync -avP /opt/ccpldata/ccplnewdata" | grep -v grep | wc -l`
# BKP_LOC_SRC='/opt/ccpldata/ccplnewdata'
# #BKP_LOC_DST='/opt/backup/backup_of_opt_ccpldata_ccplnewdata_20-12-2024/'
# BKP_LOC_DST='/opt/backup/backup_of_opt_ccpldata_ccplnewdata_latest/'
# RSYNC_EMAIL_FILE='/home/cce/rayo/scripts/github/cce/ubuntu-local-setup/roles/home_ubuntu_setup/files/cceplrsyncmail.py'

# echo "Backup Source Location: $BKP_LOC_SRC"
# echo "Backup Destination Location: $BKP_LOC_DST"


# echo "Number of rsync process: $PS1"


ccersync () {

	if [ $PS1 -gt 1 ];
	then
          echo "Rsync is running."
        else
          starttime=$(date +'%d-%m-%Y-%H%M%S')
	  echo "TASK STARTS AT : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	  echo "START rsync at : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	  echo "BEFORE - Check for rsync backup log: /home/cce/logs/rsync/rsync_in_backup_location_${DC}_$starttime.log" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log

          rsync -avP $BKP_LOC_SRC $BKP_LOC_DST >> /home/cce/logs/rsync/rsync_in_backup_location_${DC}_$starttime.log 2>&1

	  echo "AFTER - Check for rsync backup log: /home/cce/logs/rsync/rsync_in_backup_location_${DC}_$starttime.log" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	  echo "END rsync at : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	  echo "Rysnc is finished : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	  
	  sleep 5

          echo "Re-verifying if Rsync is running : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log

          if [ $PS1 -gt 1 ];
          then
            echo "Rsync is still running : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
          else
	    echo "Reverified and confiremd that Rsync is finished : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	    echo "Going to poweroff : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	    echo "Capture Time Before Server Powered Off : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	    echo "Powered Off server at : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	    echo "Final Cron Job Completed at : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	    echo "TASK ENDS AT : $(date)" >> /home/cce/logs/rsync/rsync_cron_${DC}_$starttime.log
	    python3 $RSYNC_EMAIL_FILE
	    sleep 5
	    #sudo /usr/sbin/reboot
	    # sudo /usr/sbin/poweroff
	    echo "Poweroff command exeection" 
	  fi  

        fi
}

ccersync
