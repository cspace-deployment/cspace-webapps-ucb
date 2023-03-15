#!/usr/bin/env bash

# update transaction database with latest data from a snowcone

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

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
sqlite3 ${SQLITE3_DB}  << HERE
-- refresh temp table
DROP TABLE IF EXISTS merritt_temp;
CREATE TABLE IF NOT EXISTS "merritt_temp" (
  "accession_number" text NOT NULL,
  "image_filename" text NOT NULL,
  "status" text NOT NULL,
  "job" text NOT NULL,
  "transaction_date" datetime NOT NULL,
  "transaction_detail" text);

-- clean out old data, if any, for *this* snowcone
DELETE FROM merritt_archive_transaction WHERE status = 'snowcone' AND job = '${SNOWCONE}';

-- import new rows
.mode tabs
.import ${FILENAME} merritt_temp

insert into merritt_archive_transaction
  (accession_number, image_filename, status, job, transaction_date, transaction_detail)
  select * from merritt_temp;

-- check database contents
select status,count(*) from merritt_archive_transaction group by status;
select status,job,count(*) from merritt_archive_transaction where status = 'snowcone' group by status, job;

-- tidy up
DROP TABLE IF EXISTS merritt_temp;
VACUUM;
HERE

rm ans fns filler s3_filenames.csv

