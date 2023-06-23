#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

TENANT=ucjeps
CORE=merritt
CSVFILE="$1"
RECORD_TYPE="$2"
COLUMNS=$(echo -e 'accession_number_s\timage_filename_s\tstatus_s\tjob_s\ttransaction_date_dt\ttransaction_detail_s')
# insert column header into input file
echo "$COLUMNS" > hdr
cat hdr ${CSVFILE} > temp.csv
# zap some records in the existing core, if we are instructed to refresh
if [ "$3" == "refresh" ]; then
  echo "we zap the ${RECORD_TYPE} records in solr/${TENANT}-${CORE} first..."
  curl -S -s "${SOLR_SERVER}/solr/${TENANT}-${CORE}/update" --data '<delete><query>status_s:'${RECORD_TYPE}'</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
else
  echo "POSTing ${CSVFILE}, i.e. adding documents to existing solr/${TENANT}-${CORE} ..."
fi
SOLRCMD="${SOLR_SERVER}/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&trim=true&separator=%09"
##############################################################################
# the heavy lifting starts...
##############################################################################
echo "time curl -X POST -S -s "${SOLRCMD}" -H 'Content-type:text/plain; charset=utf-8' -T temp.csv"
time curl -X POST -S -s "${SOLRCMD}" -H 'Content-type:text/plain; charset=utf-8' -T temp.csv
rm temp.csv hdr
if [ $? != 0 ]; then
  MSG="Solr POST failed for ${TENANT}-${CORE}, file ${CSVFILE}"
  echo $MSG
  echo "${MSG}" | mail -r "cspace-support@lists.berkeley.edu" -s "PROBLEM ${TENANT}-${CORE} solr refresh failed" -- ${NOTIFY}
else
  MSG="refresh of ${TENANT}-${CORE} succeeded."
  echo $MSG
  echo "${MSG}" | mail -r "cspace-support@lists.berkeley.edu" -s "PROBLEM ${TENANT}-${CORE} solr refresh failed" -- ${NOTIFY}
fi
# commit the updates: only needed if we deleted stuff but we can just do it anyway
curl -S -s "${SOLR_SERVER}/solr/${TENANT}-${CORE}/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
