#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

export RUN_DATE=`date +%Y-%m-%d-%H-%M`
DB_NAME=`basename ${SQLITE3_DB}`
# make a backup
echo aws s3 cp ${SQLITE3_DB} ${S3URI}/${DB_NAME}.backup.${RUN_DATE}
aws s3 cp ${SQLITE3_DB} ${S3URI}/${DB_NAME}.backup.${RUN_DATE}
