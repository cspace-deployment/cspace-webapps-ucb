#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

IMAGE_FILE_NAME="$1"
TRANSACTION_TYPE="$2"
ACCESSION_NUMBER="${IMAGE_FILE_NAME/_*/}"
ACCESSION_NUMBER="${ACCESSION_NUMBER/.*/}"

if [[ "$3" == "-v" ]]
then
  RESULT=$(curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?indent=true&q.op=OR&q=accession_number_s%3A${ACCESSION_NUMBER}&rows=100")
  echo $RESULT | jq
else
  RESULT=$(curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?indent=true&q.op=OR&q=accession_number_s%3A${ACCESSION_NUMBER}%20AND%20status_s:${TRANSACTION_TYPE}&rows=1")
  echo $RESULT | jq -r '.response.docs[0].transaction_detail_s' | grep -v null
fi
