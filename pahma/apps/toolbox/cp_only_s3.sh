#!/usr/bin/env bash

if [[ $# -ne 2 ]] ; then
  echo "two arguments required: localfilepath s3target"
  exit 1
fi

source /home/app_cspace/bin/set_environment.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

/usr/bin/aws s3 cp "$1" s3://${BL_ENVIRONMENT}/$2
echo "/usr/bin/aws s3 cp \"$1\" s3://${BL_ENVIRONMENT}/$2"
rm -f "$1"
