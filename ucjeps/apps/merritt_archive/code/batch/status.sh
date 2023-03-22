#!/usr/bin/env bash

echo "records in ucjeps archiving transaction database, counts by type"
echo

sqlite3 /var/www/ucjeps/db.sqlite3 "select CURRENT_DATE,status,count(*) from merritt_archive_transaction group by status;" | perl -pe 's/\|/\t/g' | expand -12

echo
echo "jobs completed as of today `date`"
echo
wc -l /cspace/merritt/jobs/*.completed.csv
echo

