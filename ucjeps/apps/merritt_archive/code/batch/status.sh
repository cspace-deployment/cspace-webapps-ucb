#!/usr/bin/env bash

echo "records in ucjeps archiving transaction database, counts by type"
echo "as of $(date)"
echo

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?facet.field=status_s&facet=true&indent=true&q.op=OR&q=*%3A*&rows=0" | \
jq -r '.facet_counts.facet_fields.status_s'

echo
echo 'snowcones'
echo
curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?facet.field=job_s&facet=true&indent=true&q.op=OR&q=status_s:snowcone&rows=0" | \
jq -r '.facet_counts.facet_fields.job_s'
echo

echo 'archivable'
echo
curl -S -s "${SOLR_SERVER}/solr/ucjeps-merritt/select?facet.field=job_s&facet=true&indent=true&q.op=OR&q=status_s:archivable&rows=0" | \
jq -r '.facet_counts.facet_fields.job_s'
echo

echo "jobs completed as of today `date`"
echo
wc -l /cspace/merritt/jobs/*.completed.csv
echo
