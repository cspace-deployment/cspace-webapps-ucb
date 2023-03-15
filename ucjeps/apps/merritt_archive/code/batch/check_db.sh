#!/usr/bin/env bash
#

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }
SQL="sqlite3 ${SQLITE3_DB}"

IMAGE_FILE_NAME="$1"
TRANSACTION_TYPE="$2"
ACCESSION_NUMBER="${IMAGE_FILE_NAME/_*/}"
ACCESSION_NUMBER="${ACCESSION_NUMBER/.*/}"

SQL_QUERY="select transaction_detail from merritt_archive_transaction where status = '${TRANSACTION_TYPE}' and accession_number = '${ACCESSION_NUMBER}';"

#echo "${ACCESSION_NUMBER}"
RESULT=`${SQL} "${SQL_QUERY}"`
echo "${RESULT}"

