#!/usr/bin/env bash

# runs on blackight-prod
# send only the 'completed' and bmu job files to ucjeps-iap from blacklight-prod
# get new jobs files from ucjeps-iap, but not the bmu or 'completed' files

echo syncing at $(date)
aws s3 sync --no-progress --exclude '*' --include '*completed*' --include 'bmu-*' /cspace/merritt/jobs/ s3://cspace-merritt-in-transit-prod/jobs/
aws s3 sync --no-progress --exclude '*inprogress*' --exclude '*completed*' --exclude 'bmu-*' s3://cspace-merritt-in-transit-prod/jobs/ /cspace/merritt/jobs/
