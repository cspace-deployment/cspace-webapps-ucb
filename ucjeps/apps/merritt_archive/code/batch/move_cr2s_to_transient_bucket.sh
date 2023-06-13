#!/usr/bin/env bash

# copy cr2 file from ucjeps s3 bucket to rtl transient bucket

set -o errexit
source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

if [[ $# -ne 1 ]] ; then
  echo "Usage: $0 inputfile"
  exit 1
fi

INPUTFILE="$1"

while IFS=$'\t' read -r CR2
  do
    CR2_FILENAME=`basename -- "${CR2}"`
    echo aws s3 cp --quiet \"${UCJEPS_BUCKET}/${CR2}\" \"${S3URI}/${CR2_FILENAME}\"
    aws s3 cp --quiet "${UCJEPS_BUCKET}/${CR2}" "${S3URI}/${CR2_FILENAME}"
  done < ${INPUTFILE}

