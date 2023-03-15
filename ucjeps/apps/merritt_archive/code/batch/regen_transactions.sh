#echo "extracting test filenames from s3..."
#aws s3 ls --recursive s3://blacklight-qa/bmu/ucjeps | perl -pe 's/ +/\t/g' > allBMU.csv

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

echo "extracting filenames from snowcone1.txt..."
perl -pe 's#Transfer//##' snowcone1.txt > s3_filenames.csv

echo "munging filenames to load into database..."
#perl -pe "s/\t/ /;s#(.*)\t(.*)\t(.*)/(.*)\.(.*)#\4\t\4.\5\tsnowcone\t\t\1\t\3/\4.\5#" s3_filenames.csv > merritt_archive.csv

perl -ne 'use File::Basename; chomp; print basename($_)."\n"' s3_filenames.csv > fns
perl -pe 's/_.*//;s/\..*?$//' fns > ans
perl -ne 'chomp;print "snowcone\t999\t2023-03-03\n"' ans > filler
paste ans fns filler s3_filenames.csv > mrt
cat transaction_db_header.csv mrt > merritt_archive.csv

echo "extracting metadata from 4solr file..."
#cut -f3,4,6,8,9,10,11 4solr.ucjeps.public.csv
cut -f3,4,8,9,10,52 4solr.ucjeps.public.csv | perl -pe 's#\t# / #g;s# / #\t\tmetadata\t\t\t#;s/\|/, /g' > metadata.csv

echo "regenerating sqlite3 database..."
sqlite3 ${SQLITE3_DB}  < regen_transactions.sql

rm ans fns mrt filler

