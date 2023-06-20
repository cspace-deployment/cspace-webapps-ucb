#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?q=status_s%3Aarchived&fl=image_filename_s&rows=1000000" | jq -r '.response.docs[].image_filename_s'