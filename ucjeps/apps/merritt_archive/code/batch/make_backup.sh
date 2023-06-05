#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

export RUN_DATE=`date +%Y-%m-%d-%H-%M`
DB_NAME=`basename ${SQLITE3_DB}`
# make a gzipped backup
cp ${SQLITE3_DB} /tmp/${DB_NAME}.backup.${RUN_DATE}
gzip /tmp/${DB_NAME}.backup.${RUN_DATE}
echo aws s3 cp --quiet /tmp/${DB_NAME}.backup.${RUN_DATE}.gz ${S3URI}/${DB_NAME}.backup.${RUN_DATE}.gz
aws s3 cp --quiet /tmp/${DB_NAME}.backup.${RUN_DATE}.gz ${S3URI}/${DB_NAME}.backup.${RUN_DATE}.gz
rm /tmp/${DB_NAME}.backup.${RUN_DATE}.gz
