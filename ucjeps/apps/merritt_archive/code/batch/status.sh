#!/usr/bin/env bash

echo "records in ucjeps archiving transaction database, counts by type"
echo

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

sqlite3 ${SQLITE3_DB} "select CURRENT_DATE,status,count(*) from merritt_archive_transaction group by status;" | perl -pe 's/\|/\t/g' | expand -12

echo
echo "jobs completed as of today `date`"
echo
wc -l /cspace/merritt/jobs/*.completed.csv
echo

