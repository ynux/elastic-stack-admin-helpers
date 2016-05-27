#!/bin/bash

# Prereq:      We use the elastic licensed product Watcher. 
# Purpose:     SPOOL, PUT, UPDATE or DELETE a watch. 
#              Workflow for updating a watch: 
#              1. Spool the definition and state of your watch
#              2. Manually edit the watch definition, removing status and other metainformation
#                 and write to $WATCH_ID.json
#              3. UPDATE (= DELETE and PUT)
#    
# 2016.05.27   S.Kim

SCRIPTNAME=$(basename $0 .sh)
LOGDIR=.
LOGFILE=${LOGDIR}/${SCRIPTNAME}.log

type curl >/dev/null 2>&1 || { echo >&2 "This script requires curl but it's not installed."; exit 3; }
type json_pp >/dev/null 2>&1 || { echo >&2 "This script requires json_pp but it's not installed."; exit 3; }

function usage {
   echo "Usage: $(basename $0) HOST_ADDRESS WATCH_ID ACTION [USERNAME PASSWORD] "
   echo "provide USERNAME PASSWORD if using Shield. ACTION is one of SPOOL, DELETE, PUT, UPDATE ".
}

HOST=$1
WATCH_ID=$2
ACTION=$3
USERNAME=$4
PASSWORD=$5

if [ ! $# -eq 5 -a ! $# -eq 3 ]; 
  then usage
  exit 1
fi

if [ -z $USERNAME -a -z $PASSWORD ]
  then CREDENTIALS=""
else
  CREDENTIALS=" -u $USERNAME:$PASSWORD"
fi

echo "$(date) : Starting $SCRIPTNAME" >> $LOGFILE

# Spool the definition and state of your watch
SPOOLFILE=${LOGDIR}/${WATCH_ID}_def_status.json
if [ $ACTION != "PUT" ]; then
  echo "$(date) : Spooling definition of watch $WATCH_ID into $SPOOLFILE" | tee -a $LOGFILE
  /usr/bin/curl $CREDENTIALS -s $HOST:9200/_watcher/watch/$WATCH_ID | json_pp > $SPOOLFILE | tee -a $LOGFILE

  # Some error handling in case curl failed
  # "status" : 401
  if [ $(grep -c '"status" : ' $SPOOLFILE) -eq 1 ]; then
    echo "Sorry, your curl failed"
    exit 1
  fi
  
  # Some error handling in case the watch wasn't found
  # "status" : 401
  if [ $(grep -c '"found" : false' $SPOOLFILE) -eq 1 ]; then
    echo "Sorry, watch $WATCH_ID not found"
    exit 1
  fi
fi

# Basic check of the json file with the new definition, before deleting the watch
# (Would be better to put and delete a temp watch)
if [ $ACTION != "DELETE" -a $ACTION != "SPOOL" ]; then
  if [ ! -f $WATCH_ID.json ]; then
    echo "Sorry, can't find your $WATCH_ID.json file"
    exit 1
  fi

  echo "$(date) : Checking the json of your $WATCH_ID.json" | tee -a $LOGFILE
  cat $WATCH_ID.json | json_pp > /dev/null 
  JSON_CHECK=$?
  if [ $JSON_CHECK -ne 0 ]; then  
    echo "Sorry, there's something wrong with your json in $WATCH_ID.json ."  
    exit 1
  fi
fi

# delete the watch
if [ $ACTION != "PUT" -a $ACTION != "SPOOL" ]; then
  echo "$(date) : Deleting watch $WATCH_ID " | tee -a $LOGFILE

  /usr/bin/curl -XDELETE $CREDENTIALS -s $HOST:9200/_watcher/watch/$WATCH_ID | tee -a $LOGFILE
fi

# put the watch
if [ $ACTION != "DELETE" -a $ACTION != "SPOOL" ]; then
  echo "$(date) : Putting watch $WATCH_ID " | tee -a $LOGFILE
  
  /usr/bin/curl -XPUT $CREDENTIALS -s $HOST:9200/_watcher/watch/$WATCH_ID  -d@$WATCH_ID.json | tee -a $LOGFILE
  
  echo "$(date) : Checking if your watch $WATCH_ID is there" | tee -a $LOGFILE
  
  /usr/bin/curl $CREDENTIALS -s $HOST:9200/_watcher/watch/$WATCH_ID | json_pp > /tmp/$WATCH_ID.json | tee -a $LOGFILE
  
  # If not found, something went really wrong!
  if [ $(grep -c '"found" : false' /tmp/$WATCH_ID.json) -eq 1 ]; then
    echo " ######### "
    echo "Sorry, watch $WATCH_ID not found"
    echo " ######### "
    exit 1
  fi
fi

echo "$(date) : Finished $SCRIPTNAME" | tee -a $LOGFILE

exit 0


