#!/usr/bin/env bash

echo "extracting metadata from 4solr file..."
cp /cspace/solr_cache/4solr.ucjeps.public.csv.gz .
gunzip -f 4solr.ucjeps.public.csv.gz
cut -f3,4,8,9,10,52 4solr.ucjeps.public.csv | perl -pe 's#\t# / #g;s# / #\t\tmetadata\t\t\t#;s/\|/, /g' > metadata.csv
rm 4solr.ucjeps.public.csv

echo "extracting media info from 4solr file..."
cp /cspace/solr_cache/4solr.ucjeps.allmedia.csv.gz .
gunzip -f 4solr.ucjeps.allmedia.csv.gz
# remove the last line, for now
head -n -1 4solr.ucjeps.allmedia.csv > temp.txt ; mv temp.txt 4solr.ucjeps.allmedia.csv

export RUN_DATE=`date +%Y-%m-%dT%H:%M`
cut -f2,5 4solr.ucjeps.allmedia.csv > m1.csv
cut -f8 4solr.ucjeps.allmedia.csv > m2.csv
perl -ne 'chomp;print "media\t\t$ENV{'RUN_DATE'}\n"' m2.csv > filler
paste m1.csv filler m2.csv > media.csv

rm 4solr.ucjeps.allmedia.csv m1.csv m2.csv filler

./make_backup.sh

echo "updating sqlite3 database..."
sqlite3 merritt_archive.sqlite3 << HERE
-- clear out old rows
DELETE FROM merritt_archive_transaction WHERE status = 'metadata';
DELETE FROM merritt_archive_transaction WHERE status = 'media';
-- import new rows
.mode tabs
.import metadata.csv merritt_archive_transaction
.import media.csv merritt_archive_transaction

select status,count(*) from merritt_archive_transaction group by status;
HERE

rm metadata.csv media.csv

