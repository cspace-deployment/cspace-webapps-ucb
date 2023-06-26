#!/usr/bin/env bash

# tidy up files from 5 before last date of archiving activity

cd /cspace/merritt/batch
FILES_TO_DELETE=$(ls /cspace/merritt/jobs/mrt-*.completed.csv | tail -5 | head -1)
echo tidying up $FILES_TO_DELETE
./step5_tidy_up.sh $FILES_TO_DELETE > /dev/null
