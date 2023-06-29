#!/usr/bin/env bash

# check the various sources of Arks and ensure we are capturing them
# has to run on blacklight-prod as it expects to check the webapp log

# from completed jobs files
cat ../jobs/mrt-2023-0* > archived.completed-raw.csv
perl -pe '/^(.*?)\t/ && ($a = $1); $a =~ s/[_\.].*//; print "$a\t"; s/\t/\tarchived\t\t/' archived.completed-raw.csv | perl -pe 's/\r//g;' | cut -f1-6 > archived.completed.csv
# from logs
./get-archived.sh
# from solr
./extract_archived_images.sh | perl  -pe 'if (/TIF.*TIF/){s/^(.*?)[_\.].*?\t/\1\t/}' > archived.fromdb.csv
cat archived.completed.csv archived.details.csv archived.transactions.csv archived.fromdb.csv |\
     perl -pe 's/\-07:00\t/Z\t/' |\
     grep "ark:" |\
     sort -u > a.temp
perl -ne '@x=split /\t/; print unless $seen{$x[1]}++;' a.temp > archived.all.csv
aws s3 sync --no-progress --exclude '*' --include 'archived.*.csv' . s3://cspace-merritt-in-transit-prod/archived
rm a.temp

