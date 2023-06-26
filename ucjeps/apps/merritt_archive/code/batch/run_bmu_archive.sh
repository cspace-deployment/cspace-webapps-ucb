#!/usr/bin/env bash

# archive bmu images from day before yesterday

JOBS="bmu-$(date -d "2 days ago" +%Y-%m-%d)"
cd /cspace/merritt/jobs
JOBFILES=$(ls $JOBS*.input.csv)
cd /cspace/merritt/batch
for JOB in $JOBFILES; do
  #echo ./pipeline_helper.sh ${JOB/.input.csv/}
  ./pipeline_helper.sh ${JOB/.input.csv/}
done
