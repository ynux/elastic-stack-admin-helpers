#!/bin/bash

# Prereq:      We use the elastic licensed product Watcher. 
# Purpose:     Spool json definition and state of watches to disk
#              for versioning (e.g. in git), backup and easier update 
#    
# 2016.05.27   S.Kim

SCRIPTNAME=$(basename $0 .sh)
LOGDIR=/mnt/backup/watches
LOGFILE=${LOGDIR}/${SCRIPTNAME}.log
JSONFILE=${LOGDIR}/${SCRIPTNAME}.json

type curl >/dev/null 2>&1 || { echo >&2 "This script require curl but it's not installed."; exit 3; }

function usage {
   echo "Usage: $(basename $0) HOST_ADDRESS USERNAME PASSWORD"
}

HOST=$1
USERNAME=$2
PASSWORD=$3

if [ ! -d $LOGDIR -o ! -w $LOGDIR ]
  then echo "Logdir $LOGDIR doesn't exist, or isn't writable. Exiting."
  exit 2
fi

if [ -z $USERNAME -a -z $PASSWORD ]
  then CREDENTIALS=""
else
  CREDENTIALS=" -u $USERNAME:$PASSWORD"
fi

echo "$(date) : Starting $SCRIPTNAME" | tee -a $LOGFILE

WATCHES=$(/usr/bin/curl $CREDENTIALS -s $HOST:9200/_cat/count/.watches)
if [ $(echo $WATCHES | grep -wc error) -gt 0 ]; then
  echo "You got an error in your first curl, exiting" | tee -a $LOGFILE
  exit 2 
else
  $NUM_WATCHES=$(echo $WATCHES | cut -d" "  -f3)
fi

echo "$(date) : Getting the json of your $NUM_WATCHES .watches ..." | tee -a $LOGFILE

/usr/bin/curl $CREDENTIALS -s $HOST:9200/.watches/_search?size=$NUM_WATCHES | json_pp > $JSONFILE 

for WATCH in $(cat $JSONFILE  | grep -w _id | cut -d\"  -f4); do
  echo "getting definition and status for $WATCH "
  /usr/bin/curl $CREDENTIALS -s $HOST:9200/_watcher/watch/$WATCH | json_pp > $LOGDIR/$WATCH.json 
done

echo "$(date) : Finished $SCRIPTNAME" | tee -a $LOGFILE

exit 0



