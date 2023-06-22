#!/usr/bin/env bash

# this script scrapes the merritt callback info (in json) from the webapp logs
# and keeps a copy just in case

grep 'jobState' /cspace/webapps_logs/ucjeps.webapps.log* > arc.json
cat arc.json | grep -v 'could not'  | perl -ne 'print unless /job",$/' | perl -pe "s/^.*?{/{/;s/}'? :: .*/}/;" | perl -pe 's/job://g;' | jq -r '.[] | [.localID,.completionDate,.primaryID,.objectTitle]|@tsv' > x1
cat arc.json | grep 'could not'  | perl -pe "s/^.*?{/{/;s/}'? :: .*/}/;" | perl -pe 's/job://g;' > x2
perl -pe "s/(\\\x[[:xdigit:]]{2})//eg;s/\\\\\\\/\\\/g;s/\\\'/'/g" x2 > x3
cat x3 | jq -r '.[] | [.localID,.completionDate,.primaryID,.objectTitle]|@tsv' > x4
cat x1 x4 all.archived.csv | sort -u > x5
mv x5 all.archived.csv
wc -l all.archived.csv
rm x?
