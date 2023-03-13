#!/bin/bash

set -o errexit

RUN_DATE=`date +%Y-%m-%dT%H-%M`
source step1_set_env.sh
time ./step2_filter.sh $1.input.csv 
time ./step3_processCR2s.sh $1.cr2s.csv ${RUN_DATE}
time ./step4_send_to_merritt.sh $1.tiffs.csv

ls -tr $1.*.csv | xargs wc -l

