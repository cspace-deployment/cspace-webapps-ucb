#!/usr/bin/env bash

IMAGE_FILE_NAME="$1"
TRANSACTION_TYPE="$2"
ACCESSION_NUMBER="${IMAGE_FILE_NAME/_*/}"
ACCESSION_NUMBER="${ACCESSION_NUMBER/.*/}"

RESULT=$(curl -S -s "http://localhost:8983/solr/ucjeps-merritt/select?indent=true&q.op=OR&q=accession_number_s%3A${ACCESSION_NUMBER}%20AND%20status_s:${TRANSACTION_TYPE}&rows=9")

echo $RESULT | jq -r '.response.docs[0].transaction_detail_s'
