### Being a laundry list of bash commands, etc. useful in pipelin development

The following assortment of command lines may be of use.
```bash
# how to deploy the pipeline from github
cd ~/cspace-webapps-ucb/
git pull -v

# make directories for the code and jobs
rm -rf /cspace/merritt/batch
rm -rf /cspace/merritt/web
mkdir /cspace/merritt
mkdir /cspace/merritt/jobs

cp -r ~/cspace-webapps-ucb/ucjeps/apps/merritt_archive/code/* /cspace/merritt
cd /var/www/static/
rm thumbs
ln -s /cspace/merritt/web thumbs

# steps to make the pipeline go.

# edit credentials
cp step1_set_env.sh.example step1_set_env.sh
vi step1_set_env.sh

# set env vars
source step1_set_env.sh

# you made a test file containing the full path
# of some files in the merritt s3 bucket right?
# it has to be named like "something.input.csv"

# pull out just the archivable cr2 files from the list
time ./step2_filter.sh something.input.csv

# pull the cr2s from s3 and make them into tiffs
# in our s3 bucket
time ./step3_processCR2s.sh something.cr2s.csv ${RUN_DATE}

# make a manifest and post it to merritt ingest
time ./step4_send_to_merritt.sh something.tiffs.csv

# check the results (i.e counts of rows in files)
ls -tr something.*.csv | xargs wc -l

# how to use ucjeps_cps3.sh by itself to copy
# media to and from ec2 and s3
# nb: env vars must be set (see above)!
cd ~/bin/merritt-pipeline/
./ucjeps_cps3.sh UC1039940.CR2 ucjeps from username:password jepson-snowcone.uc3dev.cdlib.org
./ucjeps_cps3.sh UC1039940.CR2 ucjeps to '' ''

# here's how to copy one image from merritt's s3 bucket to /tmp
./ucjeps_cps3.sh "SNOWCONE_1A/Mexico/ImageStation1/01 June 2016/UC2031043.CR2" ucjeps from username:password jepson-snowcone.uc3dev.cdlib.org

# here's how to do it using curl
curl -s -S -L 'https://username:password@jepson-snowcone.uc3dev.cdlib.org/SNOWCONE_1C/ImageStation1_2019_backup/2019/Fungi/Micro Fungi/13 April 2017/F_2017_04_13_st1_cr2/UC1060745.CR2' > /tmp/UC1060745.CR2

# provisioning the transaction database
cp /cspace/solr_cache/4solr.ucjeps.public.csv.gz .
cp /cspace/solr_cache/4solr.ucjeps.allmedia.csv.gz .
gunzip -f *.gz
aws s3 cp s3://cspace-merritt-in-transit-qa/checked.csv.gz .
gunzip checked.csv.gz 
aws s3 cp s3://cspace-merritt-in-transit-qa/snowcone1.txt .

# if you need to wget them from aws (e.g. to your local laptop)
wget https://webapps.cspace.berkeley.edu:/4solr.ucjeps.allmedia.csv.gz  
wget https://webapps.cspace.berkeley.edu:/4solr.ucjeps.public.csv.gz  
gunzip -f 4solr.ucjeps.allmedia.csv.gz 
gunzip -f 4solr.ucjeps.public.csv.gz 

# copy one test cr2 from the bmu cache on s3
aws s3 cp s3://blacklight-prod/bmu/ucjeps/UC181414.CR2 .

# possible ways to make test files
grep CR2 snowcone1.txt| awk 'NR % 1000 == 0' | perl -pe "s#^Transfer//##" | tail -50 > snow-test-50.input.csv
grep CR2 snowcone1.txt| awk 'NR % 20000 == 0' | perl -pe "s#^Transfer//##" | tail -4 > snow-test-4.input.csv
nohup time ./run_pipeline.sh snow-test-4.input.csv &
nohup time ./run_pipeline.sh snow-test-4 &

# assorted commands to check various things
basename -- "SNOWCONE_1A/eLoans-MISC-Other/Lichens-CHECKfforDUPS/MyBookEssential28962/2013/L 25 Oct 2013/L 25 Oct CR2/UC2000211.CR2"
nohup time ./step5_processCR2s.sh snow-test-4.cr2s.csv 9999 &
./check_db.sh UC2000211 metadata

# make the 'snowcone list' file into a proper input file (i.e. filename tab full_path)
perl -pe 's#Transfer//##' snowcone1.txt > s3_filenames.csv
less s3_filenames.csv 
perl -pe 'use File::Basename; chomp; print "\n".basename($_)."\t"' s3_filenames.csv | grep "\.CR2" | less

# useful sqlite3 commands for testing transaction database
# see also regen_transactions.sh and regen_transaction.sql
.tables
.table merritt_archive_transaction
.schema merritt_archive_transaction 
select count(*) from merritt_archive_transaction ;
select * from merritt_archive_transaction limit 3;
select * from merritt_archive_transaction where image_filename like 'JEPS11947%' limit 10;
select * from merritt_archive_transaction where merritt_archive_transaction.image_filename like 'JEPS11947%' limit 10;

# import a test file
COPY merrit_archive (accession_number, image_filename, status, job, transaction_date, transaction_detail) FROM '/home/app_cspace/merritt/merritt_archive.csv' DELIMITER E'\t' CSV

# find the accession number / image name mismatches
perl -ne '@x = split("\t"); $x[4] =~ s/.JPG//i; $x[4] =~ s/_\d+//; $x[4] =~ s/[acb]$// ; next if ($x[1] eq ""); next if / deleted/ ; if ($x[1] ne $x[4]) {print $_ }' 4solr.ucjeps.allmedia.csv > number_image_mismatch.csv

# how to make a list of the current duplicate accession numbers
# nb: since number uniqueness is now enforced in the database
# these are the numbers that are marked "dup" in some way...
cut -f3 4solr.ucjeps.public.csv | sort -u > unique.accessions.txt
cut -f1 -d" " unique.accessions.txt | sort | uniq -c | sort -rn | grep -v ' 1 ' | perl -pe 's/^ +\d //' > unique.dedup.txt

```

