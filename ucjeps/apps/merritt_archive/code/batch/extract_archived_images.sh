#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?q=status_s%3Aarchived&fl=accession_number_s,image_filename_s,status_s,job_s,transaction_detail_s,transaction_date_dt&rows=1000000" |\
  jq -r '.response.docs[] | [.accession_number_s,.image_filename_s,.status_s,.jobs_s,.transaction_date_dt,.transaction_detail_s]|@tsv' |\
  sort -u
