#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

SNOWCONE="$2"
CR2=`grep "$1" "$SNOWCONE" | head -1 | cut -f6`

if [[ "$CR2" == "" ]]
then
  echo "$1 is not on $SNOWCONE."
  exit 1
fi

echo $CR2
# fetch the CR2 from S3
echo "./ucjeps_cps3.sh \"$CR2\" ucjeps from"
./ucjeps_cps3.sh "${CR2}" ucjeps from ${UCJEPS_BUCKET} 2>&1

