#!/usr/bin/env bash

# sync jobs files from this server to s3 bucket

cd /cspace/merritt
mkdir jobs2sync
cp jobs/* jobs2sync
rm -f jobs2sync/*.inprogress.csv
tar czf jobs.tgz jobs2sync
# put the compress archive on the rtl transient prod bucket
aws s3 cp --quiet jobs$1.tgz s3://cspace-merritt-in-transit-prod
# copy the jobs file to the helpers bucket
aws s3 sync --quiet jobs s3://ucjeps-kept/jobs
rm jobs$1.tgz
rm -rf jobs2sync
