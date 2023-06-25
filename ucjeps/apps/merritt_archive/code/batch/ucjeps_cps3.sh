#!/usr/bin/env bash

# s3 image transfer script for ucjeps archiving project. goes both ways.

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

if [[ $# -ne 3 ]] ; then
  echo "three arguments required: filepath museum (from/to)"
  exit 1
fi

FILEPATH="$1"
FILENAME=`basename -- "${FILEPATH}"`
MUSEUM="$2"
DIRECTION="$3"
MERRITT_TRANSIT="${S3URI}"

echo "copying ${FILENAME} ${DIRECTION} S3  ..."

#exit 0

s=0
if [[ "${DIRECTION}" == "to" ]] ; then
  if [[ ! -e  "/tmp/${FILENAME}" ]] ; then
    echo "/tmp/${FILENAME} not found. Exiting ..."
    exit 1
  fi
  for i in {1..1}; do
    echo "/usr/bin/aws s3 cp --no-progress '/tmp/${FILENAME}' '${MERRITT_TRANSIT}/${FILENAME}'"
    ${TIME_CMD} /usr/bin/aws s3 cp --no-progress "/tmp/${FILENAME}" "${MERRITT_TRANSIT}/${FILENAME}" && s=0 && break || s=$?
    echo "failed with exit code $s. retrying. attempt $i"
  done
  rm -f "/tmp/${FILENAME}"
  exit $s
elif [[ "${DIRECTION}" == "from" ]] ; then
  for i in {1..1}; do
    echo "/usr/bin/aws s3 cp --no-progress '${MERRITT_TRANSIT}/${FILEPATH}' /tmp/${FILENAME}"
    ${TIME_CMD} /usr/bin/aws s3 cp --no-progress "${MERRITT_TRANSIT}/${FILEPATH}" /tmp/${FILENAME}
    if [[ $(head -1 /tmp/${FILENAME} | grep 'not found in S3 bucket') ]] ; then
      echo "${FILENAME} not found in S3 bucket ${MERRITT_TRANSIT}"
      exit 1
    fi
    [ -e "/tmp/${FILENAME}" ] && exit 0
    echo "failed with exit code $s. retrying. attempt $i"
  done
  # did not work
  echo "copy 'from' failed. giving up."
  exit 1
else
  echo "direction must be either from or to"
  exit 1
fi
