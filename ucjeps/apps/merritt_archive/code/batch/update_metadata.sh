#!/usr/bin/env bash

# update metadata from cspace in transaction database

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

export RUN_DATE=`date +%Y-%m-%dT%H:%M`

echo "extracting metadata from 4solr file ..."
# cp /cspace/solr_cache/4solr.ucjeps.public.csv.gz .
wget https://webapps.cspace.berkeley.edu/4solr.ucjeps.public.csv.gz
gunzip -f 4solr.ucjeps.public.csv.gz
cut -f3,4,8,9,10,52 4solr.ucjeps.public.csv | perl -pe 's#\t# / #g;s# / #\t\tmetadata\t\t$ENV{'RUN_DATE'}\t#;s/\|/, /g;s/, $//' > metadata.csv

echo "extracting media info from 4solr file ..."
# cp /cspace/solr_cache/4solr.ucjeps.allmedia.csv.gz .
wget https://webapps.cspace.berkeley.edu/4solr.ucjeps.allmedia.csv.gz
gunzip -f 4solr.ucjeps.allmedia.csv.gz
# remove the last line, for now
sed '$d' 4solr.ucjeps.allmedia.csv > temp.txt ; mv temp.txt 4solr.ucjeps.allmedia.csv

cut -f2,5 4solr.ucjeps.allmedia.csv > m1.csv
cut -f8 4solr.ucjeps.allmedia.csv > m2.csv
perl -ne 'chomp;print "media\t\t$ENV{'RUN_DATE'}\n"' m2.csv > filler
paste m1.csv filler m2.csv > media.csv
rm m1.csv m2.csv filler

echo "extracting blocked images ..."
echo "first, the accession number / filename mismatches ..."
perl -ne '@x = split("\t"); $x[4] =~ s/.JPG//i; $x[4] =~ s/_\d+//; $x[4] =~ s/[acb]$// ; next if ($x[1] eq ""); next if / deleted/ ; if ($x[1] ne $x[4]) {print $_ }' 4solr.ucjeps.allmedia.csv > m1.csv
cut -f2,5 m1.csv| perl -pe 's/.JPG/.CR2/i' > m2.csv
perl -ne 'chomp;print "$_\tblocked\t\t$ENV{'RUN_DATE'}\taccession number / filename mismatch\n"' m2.csv > mismatch1.csv
rm m1.csv m2.csv

echo "next the 'live' duplicates ..."
cut -f3 4solr.ucjeps.public.csv | sort -u > unique.accessions.txt
cut -f1 -d" " unique.accessions.txt | sort | uniq -c | sort -rn | grep -v ' 1 ' | perl -pe 's/^ +\d //' > unique.dedup.txt
perl -ne 'chomp;print "$_\t\tblocked\t\t$ENV{'RUN_DATE'}\tduplicate accession number in live database\n"' unique.dedup.txt> unique.dedup.csv

echo "finally, jason alexanders ad hoc list of snowcone1 problems ..."
perl -ne 'chomp;print "$_\t\tblocked\t\t$ENV{'RUN_DATE'}\tjason alexanders ad hoc list of snowcone1 problems\n"' blocked_images_ja.csv > mismatch2.csv

rm 4solr.ucjeps.allmedia.csv
rm 4solr.ucjeps.public.csv

echo
echo "updating solr core ..."
./post_to_ucjeps_merritt.sh metadata.csv  metadata refresh
./post_to_ucjeps_merritt.sh media.csv  media refresh
./post_to_ucjeps_merritt.sh mismatch1.csv  blocked refresh
./post_to_ucjeps_merritt.sh mismatch2.csv  blocked donotrefresh
./post_to_ucjeps_merritt.sh unique.dedup.csv blocked donotrefresh

rm metadata.csv media.csv mismatch*.csv unique.dedup.* unique.accessions.txt

echo "sending notification email ..."
./status.sh  | mail -r "cspace-support@lists.berkeley.edu" -s "UCJEPS archiving progress" ${NOTIFY}

