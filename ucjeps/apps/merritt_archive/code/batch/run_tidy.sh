#!/usr/bin/env bash

cd /cspace/merritt/batch
FILES_TO_DELETE=$(ls /cspace/merritt/jobs/*.completed.csv | tail -3 | head -1)
./step5_tidy_up.sh $FILES_TO_DELETE > /dev/null
