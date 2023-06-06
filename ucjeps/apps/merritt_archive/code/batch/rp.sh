#!/usr/bin/env bash

# set -o errexit
source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

JOB="$1"

cd /cspace/merritt/batch

if [[ ! -f "/cspace/merritt/jobs/${JOB}.input.csv" ]]; then
  echo "${JOB}.input.csv does not exist; exiting."
  exit 1
fi

nohup ./run_pipeline.sh /cspace/merritt/jobs/${JOB}.input.csv | /usr/bin/ts '[%Y-%m-%d %H:%M:%S]' > /cspace/merritt/jobs/${JOB}.log

