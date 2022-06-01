#!/usr/bin/env bash

if [[ $# -ne 2 ]] ; then
  echo "two arguments required: localfilepath s3target"
  exit 1
fi

BL_ENVIRONMENT=`/usr/bin/curl -s -m 5 http://169.254.169.254/latest/meta-data/tags/instance/BL_ENVIRONMENT`
if [[ -z $BL_ENVIRONMENT || ( "$BL_ENVIRONMENT" != "dev" && "$BL_ENVIRONMENT" != "qa" && "$BL_ENVIRONMENT" != "prod" ) ]]; then
	echo "Could not fetch BL_ENVIRONMENT, are you sure you're on AWS?"
	exit 1
fi
BL_ENVIRONMENT="blacklight-${BL_ENVIRONMENT}"

/usr/bin/aws s3 cp "$1" s3://${BL_ENVIRONMENT}/$2
echo "/usr/bin/aws s3 cp \"$1\" s3://${BL_ENVIRONMENT}/$2"
# rm -f "$1"
