#!/bin/bash
#PS1=`ps -ef | grep rsync | grep -v grep | wc -l`
PS1=`ps -ef | grep "onedrive --synchronize" | grep -v grep | wc -l`

echo "Number of rsync process: $PS1"

onemon () {
	if [ $PS1 -eq 1 ];
	then
          echo "onedrive sync  is running."
        else
	  echo "running onedrive sync..."
          onedrive --synchronize
        fi
}

onemon
