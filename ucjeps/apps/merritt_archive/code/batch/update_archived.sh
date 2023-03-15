#!/usr/bin/env bash

# update transaction database with latest data regarding archived images

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

export RUN_DATE=`date +%Y-%m-%dT%H:%M`
export ARCHIVED="$1"

if [[ ! -e "${ARCHIVED}" ]]; then
  echo "usage: $0 <archived.csv>"
  echo "file '${ARCHIVED}' does not exist; exiting."
  exit 1
fi

./make_backup.sh

echo "munging archived info to load into database..."

perl -ne 'chomp;print "archived\t$ENV{'ARCHIVED'}\t$ENV{'RUN_DATE'}\n"' ${ARCHIVED} > archived.csv

echo "updating sqlite3 database..."
sqlite3 ${SQLITE3_DB}  << HERE
.mode tabs
.import archived.csv merritt_archive_transaction
select status,count(*) from merritt_archive_transaction group by status;
HERE

rm archived.csv

