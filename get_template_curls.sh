
se:     Spool json of templates to disk
#              for versioning (e.g. in git), backup and easier update 
# https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html   
# 2016.05.31   S.Kim

SCRIPTNAME=$(basename $0 .sh)
LOGDIR=/mnt/backup/templates
LOGFILE=${LOGDIR}/${SCRIPTNAME}.log
DATE=$(date +%Y%m%d)
JSONFILE=${LOGDIR}/${SCRIPTNAME}_${DATE}.json


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

/usr/bin/curl $CREDENTIALS -s $HOST:9200/_template?pretty > $JSONFILE 

if [ ! -s $JSONFILE ]
  then echo "Sorry, your $JSONFILE is empty or gone" | tee -a $LOGFILE
  exit 1
fi

echo "$(date) : Finished $SCRIPTNAME" | tee -a $LOGFILE

exit 0

