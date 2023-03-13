#!/usr/bin/env bash
#

SQL="sqlite3 merritt_archive.sqlite3"

IMAGE_FILE_NAME="$1"
TRANSACTION_TYPE="$2"
ACCESSION_NUMBER="${IMAGE_FILE_NAME/_*/}"
ACCESSION_NUMBER="${ACCESSION_NUMBER/.*/}"

SQL_QUERY="select transaction_detail from merritt_archive_transaction where status = '${TRANSACTION_TYPE}' and accession_number = '${ACCESSION_NUMBER}';"

#echo "${ACCESSION_NUMBER}"
RESULT=`${SQL} "${SQL_QUERY}"`
echo "${RESULT}"

