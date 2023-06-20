#!/usr/bin/env bash

# this script fetches the job files prepared by other servers
# and puts them in the jobs directory
# this allows all progress to be monitored in one place

aws s3 cp s3://cspace-merritt-in-transit-prod/jobs.tgz .
tar xzf jobs.tgz
rm -rf ~/jobs.bkp
cp -r /cspace/merritt/jobs/ ~/jobs.bkp
rsync -av jobs2sync /cspace/merritt/jobs
rm -rf jobs2sync

