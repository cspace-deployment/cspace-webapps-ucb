#!/usr/bin/env bash

set -o errexit

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

INPUT_FILE="$1"

if [[ ! -e "${INPUT_FILE}" ]]; then
  echo "${INPUT_FILE} does not exist; exiting."
  exit 1
fi
# remove 'suffix' from input filename
INPUT_PREFIX="${INPUT_FILE/.input.csv}"

WEBDIR=$(mktemp -d /tmp/ucjeps-archiving.XXXXXX)

time ./step2_filter.sh ${INPUT_PREFIX}.input.csv
time ./step3_processCR2s.sh ${INPUT_PREFIX}.cr2s.csv "${WEBDIR}"
time ./step4_send_to_merritt.sh ${INPUT_PREFIX}.tiffs.csv

# count the number of lines in the various files involved
ls -tr ${INPUT_PREFIX}.*.csv | xargs wc -l

# WEBSITE_BUCKET is set as an env var in the pipeline
# update thumbnail viewer index.html
./update_website.sh > "${WEBDIR}/index.html"
echo aws s3 sync --quiet ${WEBDIR} ${WEBSITE_BUCKET}
aws s3 sync --quiet ${WEBDIR} ${WEBSITE_BUCKET}
#rm -rf ${WEBDIR}

