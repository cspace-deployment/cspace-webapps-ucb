#!/usr/bin/env bash

# update transaction database with latest data from a snowcone, create input file for pipeline

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

export RUN_DATE=`date +%Y-%m-%dT%H:%M`
export SNOWCONE="$1"
export SNOWCONE_DIR="/cspace/merritt/snowcones"
export SNOWCONE_PATH="${SNOWCONE_DIR}/${SNOWCONE}"

if [[ -e "${SNOWCONE_PATH}.txt" ]]; then
  echo "file '${SNOWCONE_PATH}.txt' exist; remove it in order to rerun"
  exit 1
fi

echo "make a list of files on s3://${SNOWCONE} ..."
aws s3 ls --recursive s3://${SNOWCONE} > ${SNOWCONE_PATH}.txt || { echo "problem listing contents of s3://${SNOWCONE}"; exit 1; }

echo "extracting metadata from 4solr file ..."
cp /cspace/solr_cache/4solr.ucjeps.public.csv.gz .
gunzip -f 4solr.ucjeps.public.csv.gz

echo "extracting media info from 4solr file ..."
cp /cspace/solr_cache/4solr.ucjeps.allmedia.csv.gz .
gunzip -f 4solr.ucjeps.allmedia.csv.gz
# remove the last line, for now
sed '$d' 4solr.ucjeps.allmedia.csv > temp.txt ; mv temp.txt 4solr.ucjeps.allmedia.csv

echo "extracting archived images from database ..."
./extract_archived_images.sh | cut -f3 | perl -pe 's/.TIF/.CR2/'  > archived.csv

echo "making a backup of the database"
#./make_backup.sh

echo "running evaluation script to find archivable images"
python3 \
   checkUCJEPSmedia.py \
   ${SNOWCONE_PATH}.txt \
   4solr.ucjeps.allmedia.csv \
   4solr.ucjeps.public.csv \
   archived.csv \
   ${SNOWCONE_PATH}.checked.csv \
   ${SNOWCONE_PATH}.input.csv \
   > ${SNOWCONE_PATH}.report.txt

echo "munging ${SNOWCONE} filenames to load into database ..."

# make sure all the files have the correct line endings :-(
perl -i -pe 's/\r//g' ${SNOWCONE_PATH}.*.csv
cut -f1,3,4-7 ${SNOWCONE_PATH}.checked.csv | perl -ne 'chomp;@x=split /\t/;print "$x[0]\t$x[1]\tsnowcone\t'${SNOWCONE}'\t\t".join(",",@x[2..5])."\n"' > ${SNOWCONE_PATH}.transactions.csv

cut -c32- ${SNOWCONE_PATH}.input.csv | perl -ne 'chomp; $a = $_ ; s#.*/##; $i=$_; s/[_\.].*//; print "$_\t$i\tarchivable\t'${SNOWCONE}'\t\t$a\n"' > ${SNOWCONE_PATH}.archivable.csv

echo "updating sqlite3 database ..."
sqlite3 ${SQLITE3_DB}  << HERE
-- refresh temp table
DROP TABLE IF EXISTS merritt_temp;
CREATE TABLE IF NOT EXISTS "merritt_temp" (
  "accession_number" text NOT NULL,
  "image_filename" text NOT NULL,
  "status" text NOT NULL,
  "job" text NOT NULL,
  "transaction_date" datetime,
  "transaction_detail" text);

-- clean out old data, if any, for *this* snowcone
DELETE FROM merritt_archive_transaction WHERE status = 'snowcone' AND job = '${SNOWCONE}';

-- import new rows
.mode tabs
.import ${SNOWCONE_PATH}.transactions.csv merritt_temp
.import ${SNOWCONE_PATH}.archivable.csv merritt_temp

update merritt_temp set transaction_date = datetime();

insert into merritt_archive_transaction
  (accession_number, image_filename, status, job, transaction_date, transaction_detail)
  select * from merritt_temp;

-- check database contents
select status,count(*) from merritt_archive_transaction group by status;
select status,job,count(*) from merritt_archive_transaction where status = 'snowcone' group by status, job;
select status,job,count(*) from merritt_archive_transaction where status = 'archivable' group by status, job;

-- tidy up
DROP TABLE IF EXISTS merritt_temp;
VACUUM;
HERE

echo "creating archive input files ..."
split --additional-suffix=.input.csv -a 3 -l 1000 -d ${SNOWCONE_PATH}.input.csv arc-${SNOWCONE}-
echo "$(ls ../jobs/arc-${SNOWCONE}-*.input.csv | wc -l) job files created"
mv arc-${SNOWCONE}-*.input.csv /cspace/merritt/jobs

# tidy up
rm archived.csv
rm 4solr.ucjeps.allmedia.csv
rm 4solr.ucjeps.public.csv