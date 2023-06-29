#!/usr/bin/env bash

# runs on ucjeps-iap
# send the jobs files from ucjeps-iap to blacklight prod
# and get the 'completed' files (containing the arks) and bmu-files back from there

echo syncing at $(date)
aws s3 sync --no-progress --exclude '*inprogress*' --include '*completed*' /cspace/merritt/jobs/ s3://cspace-merritt-in-transit-prod/jobs/
aws s3 sync --no-progress --exclude '*inprogress*' s3://cspace-merritt-in-transit-prod/jobs/ /cspace/merritt/jobs/
