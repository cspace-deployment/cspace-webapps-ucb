#!/usr/bin/env bash

# update metadata from cspace in transaction database

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

export RUN_DATE=`date +%Y-%m-%dT%H:%M`

echo "extracting metadata from 4solr file..."
cp /cspace/solr_cache/4solr.ucjeps.public.csv.gz .
gunzip -f 4solr.ucjeps.public.csv.gz
cut -f3,4,8,9,10,52 4solr.ucjeps.public.csv | perl -pe 's#\t# / #g;s# / #\t\tmetadata\t\t$ENV{'RUN_DATE'}\t#;s/\|/, /g' > metadata.csv
rm 4solr.ucjeps.public.csv

echo "extracting media info from 4solr file..."
cp /cspace/solr_cache/4solr.ucjeps.allmedia.csv.gz .
gunzip -f 4solr.ucjeps.allmedia.csv.gz
# remove the last line, for now
sed '$d' 4solr.ucjeps.allmedia.csv > temp.txt ; mv temp.txt 4solr.ucjeps.allmedia.csv

cut -f2,5 4solr.ucjeps.allmedia.csv > m1.csv
cut -f8 4solr.ucjeps.allmedia.csv > m2.csv
perl -ne 'chomp;print "media\t\t$ENV{'RUN_DATE'}\n"' m2.csv > filler
paste m1.csv filler m2.csv > media.csv
rm m1.csv m2.csv filler

echo "extracting blocked images..."
perl -ne '@x = split("\t"); $x[4] =~ s/.JPG//i; $x[4] =~ s/_\d+//; $x[4] =~ s/[acb]$// ; next if ($x[1] eq ""); next if / deleted/ ; if ($x[1] ne $x[4]) {print $_ }' 4solr.ucjeps.allmedia.csv > m1.csv
cut -f2,5 m1.csv| perl -pe 's/.JPG/.CR2/i' > m2.csv
perl -ne 'chomp;print "$_\tblocked\t\t$ENV{'RUN_DATE'}\t\n"' m2.csv > mismatch.csv
rm m1.csv m2.csv
rm 4solr.ucjeps.allmedia.csv

./make_backup.sh

echo "updating sqlite3 database..."
sqlite3 ${SQLITE3_DB} << HERE
-- clear out old rows
DELETE FROM merritt_archive_transaction WHERE status = 'metadata';
DELETE FROM merritt_archive_transaction WHERE status = 'media';
DELETE FROM merritt_archive_transaction WHERE status = 'blocked';

-- refresh temp table
DROP TABLE IF EXISTS merritt_temp;
CREATE TABLE IF NOT EXISTS "merritt_temp" (
  "accession_number" text NOT NULL,
  "image_filename" text NOT NULL,
  "status" text NOT NULL,
  "job" text NOT NULL,
  "transaction_date" datetime NOT NULL,
  "transaction_detail" text
  );

-- import new rows
.mode tabs

.import metadata.csv merritt_temp
.import media.csv merritt_temp
.import mismatch.csv merritt_temp

insert into merritt_archive_transaction
  (accession_number, image_filename, status, job, transaction_date, transaction_detail)
  select * from merritt_temp;

-- check database contents
select status,count(*) from merritt_archive_transaction group by status;

-- tidy up
DROP TABLE IF EXISTS merritt_temp;
VACUUM;
HERE

rm metadata.csv media.csv mismatch.csv

