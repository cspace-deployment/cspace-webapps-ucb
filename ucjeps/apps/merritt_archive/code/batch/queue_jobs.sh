#!/usr/bin/env bash

# run archiving jobs 3 at a time: start 3 in the background, wait, then start the next set

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

JOB_TYPE=$1
if [[ ! (${JOB_TYPE} == 'bmu' || ${JOB_TYPE} == 'arc') ]]; then
  echo "\"${JOB_TYPE}\" is not either bmu or arc; exiting."
  exit 1
fi

JOB_DIR=/cspace/merritt/jobs

cd /cspace/merritt/batch

i=0
shopt -s nullglob
for JOB in $JOB_DIR/${JOB_TYPE}-*.input.csv
  do
    JOB=$(basename $JOB)
    JOB=${JOB/.input.csv/}
    #echo $JOB
    if [[ -e $JOB_DIR/${JOB}.checkm ]] ; then
      echo skipping $JOB: manifest already exists
      continue
    fi
    ((i++))
    echo submitting ./run_pipeline.sh $JOB_DIR/${JOB}.input.csv
    time ./run_pipeline.sh $JOB_DIR/${JOB}.input.csv | /usr/bin/ts '[%Y-%m-%d %H:%M:%S]' &> $JOB_DIR/${JOB}.log &
    if [[ $i -eq 3 ]] ; then
      echo 'waiting...'
      wait
      i=0
    fi
  done
