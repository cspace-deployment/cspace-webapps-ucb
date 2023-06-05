#!/usr/bin/env bash

# s3 image transfer script for ucjeps archiving project. goes both ways.

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

if [[ $# -ne 5 ]] ; then
  echo "five arguments required: filepath museum direction (from/to) username:password merritbucket"
  exit 1
fi

BL_ENVIRONMENT=`/usr/bin/curl -s -m 5 http://169.254.169.254/latest/meta-data/tags/instance/BL_ENVIRONMENT`
if [[ -z $BL_ENVIRONMENT || ( "$BL_ENVIRONMENT" != "dev" && "$BL_ENVIRONMENT" != "qa" && "$BL_ENVIRONMENT" != "prod" ) ]]; then
	echo "Could not fetch BL_ENVIRONMENT, are you sure you're on AWS?"
	exit 1
fi

FILEPATH="$1"
FILENAME=`basename -- "${FILEPATH}"`
MUSEUM="$2"
DIRECTION="$3"
MERRITT_TRANSIT="cspace-merritt-in-transit-${BL_ENVIRONMENT}"
# NB: UCJEPS_BUCKET must be set as environment variable

echo "copying ${FILENAME} ${DIRECTION} S3 ..."

#exit 0

s=0
if [[ "${DIRECTION}" == "to" ]] ; then
  if [[ ! -e  "/tmp/${FILENAME}" ]] ; then
    echo "/tmp/${FILENAME} not found. Exiting..."
    exit 1
  fi
  for i in {1..1}; do
    echo "/usr/bin/aws s3 cp --quiet '/tmp/${FILENAME}' 's3://${MERRITT_TRANSIT}/${FILENAME}'"
    ${TIME_CMD} /usr/bin/aws s3 cp --quiet "/tmp/${FILENAME}" "s3://${MERRITT_TRANSIT}/${FILENAME}" && s=0 && break || s=$?
    echo "failed with exit code $s. retrying. attempt $i"
  done
  rm -f "/tmp/${FILENAME}"
  exit $s
elif [[ "${DIRECTION}" == "from" ]] ; then
  for i in {1..1}; do
    echo "/usr/bin/aws s3 cp --quiet '${UCJEPS_BUCKET}/${FILEPATH}' > /tmp/${FILENAME}"
    ${TIME_CMD} /usr/bin/aws s3 cp --quiet "${UCJEPS_BUCKET}/${FILEPATH}" > /tmp/${FILENAME}
    if [[ $(head -1 /tmp/${FILENAME} | grep 'not found in S3 bucket') ]] ; then
      echo "${FILENAME} not found in S3 bucket ${UCJEPS_BUCKET}"
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
