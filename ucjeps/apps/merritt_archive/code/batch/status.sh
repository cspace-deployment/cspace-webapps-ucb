#!/usr/bin/env bash

echo "records in ucjeps archiving transaction database, counts by type"
echo "as of $(date)"
echo

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

sqlite3 ${SQLITE3_DB} "select CURRENT_DATE,status,count(*) from merritt_archive_transaction group by status;" | perl -pe 's/\|/\t/g' | expand -12

echo
echo 'snowcones'
echo
sqlite3 ${SQLITE3_DB} "select job,count(*) from merritt_archive_transaction where status = 'snowcone' group by job;" | perl -pe 's/\|/\t/g' | expand -12
echo

echo 'archivable'
echo
sqlite3 ${SQLITE3_DB} "select job,count(*) from merritt_archive_transaction where status = 'archivable' group by job;" | perl -pe 's/\|/\t/g' | expand -12
echo

echo "jobs completed as of today `date`"
echo
wc -l /cspace/merritt/jobs/*.completed.csv
echo
