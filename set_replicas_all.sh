#!/bin/bash
#Purpose:     Set number of replicas to 1 for all indexes
#             I use this for test clusters with one node, when I left
#             the default number of replicas at 1 and all indices are yellow
# 2017.10.16   S.Kim

SCRIPTNAME=$(basename $0 .sh)

type curl >/dev/null 2>&1 || { echo >&2 "This script require curl but it's not installed."; exit 3; }

function usage {
   echo "Usage: $(basename $0) HOST_PORT USERNAME PASSWORD"
}

# e.g. https://those_aws_addresses_are_so_ugly.eu-west-1.aws.found.io:9243 
HOST_PORT=$1
# if Shield / Security is used
USERNAME=$2
PASSWORD=$3

if [ -z $USERNAME -a -z $PASSWORD ]
  then CREDENTIALS=""
else
  CREDENTIALS=" -u $USERNAME:$PASSWORD"
fi

echo "$(date) : Starting $SCRIPTNAME" 

INDICES=$(curl $CREDENTIALS -s "$HOST_PORT/_cat/indices?pri&h=index")
for INDEX in $INDICES; do
  if [ "$INDEX" == ".security" ]; then
    echo "not allowed for index .security"
  else
    echo "setting number_of_replicas for index $INDEX ... "
    /usr/bin/curl -XPUT $CREDENTIALS -s "$HOST_PORT/$INDEX/_settings?pretty" -d' {"index":{ "number_of_replicas" : 0 }}'
  fi
done

curl $CREDENTIALS -s "$HOST_PORT/_cat/indices?pri&h=index,rep"
echo "$(date) : Finished $SCRIPTNAME" 
exit 0

