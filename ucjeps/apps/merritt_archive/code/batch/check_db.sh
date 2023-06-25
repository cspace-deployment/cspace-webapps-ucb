#!/usr/bin/env bash

# checks the solr core for the key provided; returns the transaction_detail_s field (only)

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

# depending on the type of data requested, we either search for the image filename or the accession number
# default is to search for the image filename
IMAGE_FILENAME="$1"
SEARCH_KEY="${IMAGE_FILENAME}"
SEARCH_FIELD="image_filename_s"
TRANSACTION_TYPE="$2"
if [[ ! ${TRANSACTION_TYPE} =~ "archived blocked" ]]; then
    ACCESSION_NUMBER="${IMAGE_FILENAME/_*/}"
    ACCESSION_NUMBER="${ACCESSION_NUMBER/.*/}"
    SEARCH_KEY="${ACCESSION_NUMBER}"
    SEARCH_FIELD="accession_number_s"
fi

if [[ "$3" == "-v" ]]
then
  RESULT=$(curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?indent=true&q.op=OR&q=${SEARCH_FIELD}%3A${SEARCH_KEY}&rows=100")
  echo "$RESULT" | jq
else
  RESULT=$(curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?indent=true&q.op=OR&q=${SEARCH_FIELD}%3A${SEARCH_KEY}%20AND%20status_s:${TRANSACTION_TYPE}&rows=1")
  echo "$RESULT" | jq -r '.response.docs[0].transaction_detail_s' | grep -v null
fi
