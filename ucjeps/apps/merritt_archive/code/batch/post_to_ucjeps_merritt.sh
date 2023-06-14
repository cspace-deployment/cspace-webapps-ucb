#!/usr/bin/env bash
source ${HOME}/pipeline-config.sh
export SOLR_CACHE_DIR=${SOLR_CACHE_DIR}
TENANT=ucjeps
CORE=merritt
CONTACT=jblowe@berkeley.edu
CSVFILE="$1"
RECORD_TYPE="$2"
COLUMNS=$(echo -e 'accession_number_s\timage_filename_s\tstatus_s\tjob_s\ttransaction_date_dt\ttransaction_detail_s')
# insert column header into input file
echo "$COLUMNS" > hdr
cat hdr ${CSVFILE} > temp.csv
# zap the existing core, if we are instructed to refresh
# (we might be loading several into this core)
if [ "$3" == "refresh" ]; then
  echo "we zap solr/${TENANT}-${CORE} first..."
  curl -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update" --data '<delete><query>status_s:'${RECORD_TYPE}'</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
  curl -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
else
  echo "POSTing ${CSVFILE}, i.e. adding documents to existing solr/${TENANT}-${CORE} ..."
fi
SOLRCMD="http://localhost:8983/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&trim=true&separator=%09&encapsulator=\\"
SOLRCMD="http://localhost:8983/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&trim=true&separator=%09"
##############################################################################
# the heavy lifting starts...
##############################################################################
echo "time curl -X POST -S -s "${SOLRCMD}" -H 'Content-type:text/plain; charset=utf-8' -T temp.csv"
time curl -X POST -S -s "${SOLRCMD}" -H 'Content-type:text/plain; charset=utf-8' -T temp.csv
rm temp.csv hdr
if [ $? != 0 ]; then
  MSG="Solr POST failed for ${TENANT}-${CORE}, file ${CSVFILE} ; retrying using previous successful upload"
  #echo "${MSG}" | mail -r "cspace-support@lists.berkeley.edu" -s "PROBLEM ${TENANT}-${CORE} nightly solr refresh failed" -- ${CONTACT}
else
  echo "refresh of ${TENANT}-${CORE} succeeded."
fi
