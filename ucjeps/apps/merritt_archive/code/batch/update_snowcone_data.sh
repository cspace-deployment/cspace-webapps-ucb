#!/usr/bin/env bash

# update transaction database with latest data from snowcone

export RUN_DATE=`date +%Y-%m-%dT%H:%M`
export SNOWCONE="$1"
export FILENAME="${SNOWCONE}.csv"

if [[ ! -e "${SNOWCONE}" ]]; then
  echo "file '${SNOWCONE}' does not exist"
  exit 1
fi

./make_backup.sh

echo "extracting filenames from ${SNOWCONE}..."
perl -pe 's#Transfer//##' ${SNOWCONE} > s3_filenames.csv

echo "munging filenames to load into database..."

perl -ne 'use File::Basename; chomp; print basename($_)."\n"' s3_filenames.csv > fns
perl -pe 's/_.*//;s/\..*?$//' fns > ans
perl -ne 'chomp;print "snowcone\t$ENV{'SNOWCONE'}\t$ENV{'RUN_DATE'}\n"' ans > filler
paste ans fns filler s3_filenames.csv > ${FILENAME}
#paste ans fns filler s3_filenames.csv > mrt
#cat transaction_db_header.csv mrt > ${FILENAME}

echo "updating sqlite3 database..."
sqlite3 merritt_archive.sqlite3  << HERE
-- clean out old data, if any, for this snowcone
delete from merritt_archive_transaction where status = 'snowcone' and job = '${SNOWCONE}';
-- import new rows
.mode tabs
.import ${FILENAME} merritt_archive_transaction
select status,count(*) from merritt_archive_transaction group by status;
select status,job,count(*) from merritt_archive_transaction where status = 'snowcone' group by status, job;
HERE

rm ans fns filler s3_filenames.csv

