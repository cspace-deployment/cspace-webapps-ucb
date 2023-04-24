#!/usr/bin/env bash

set -o errexit

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

INPUT_FILE="$1"

if [[ ! -e "${INPUT_FILE}" ]]; then
  echo "${INPUT_FILE} does not exist; exiting."
  exit 1
fi
# remove 'suffix' from input filename, extract filename itself
INPUT_PREFIX="${INPUT_FILE/.input.csv}"
FILE_NAME=`basename "${INPUT_FILE}"`
JOB_TYPE=${FILE_NAME:0:3}
if [[ ! (${JOB_TYPE} == 'bmu' || ${JOB+TYPE} == 'arc') ]]; then
  echo "\"${JOB_TYPE}\" is not either bmu or arc; exiting."
  exit 1
fi

WEBDIR=$(mktemp -d /tmp/ucjeps-archiving.XXXXXX)

if [[ ${JOB_TYPE} == 'arc' ]]; then
  time ./step2_filter.sh ${INPUT_PREFIX}.input.csv
  time ./step3_processCR2s.sh ${INPUT_PREFIX}.cr2s.csv "${WEBDIR}"
  time ./step4_send_to_merritt.sh ${INPUT_PREFIX}.tiffs.csv
elif [[ ${JOB_TYPE} == 'bmu' ]]; then
  time ./step3_processBMU.sh ${INPUT_PREFIX}.input.csv "${WEBDIR}"
  time ./step4_send_to_merritt.sh ${INPUT_PREFIX}.tiffs.csv
else
  echo "something bad happened to JOB_TYPE \"${JOB_TYPE}\""
  exit 1
fi

# count the number of lines in the various files involved
ls -tr ${INPUT_PREFIX}.*.csv | xargs wc -l

# WEBSITE_BUCKET is set as an env var in the pipeline
# update thumbnail viewer index.html
./update_website.sh > "${WEBDIR}/index.html"
# now sync job content to s3 website
echo aws s3 sync --quiet ${WEBDIR} ${WEBSITE_BUCKET}/${JOB_TYPE}/${INPUT_PREFIX}
aws s3 sync --quiet ${WEBDIR} ${WEBSITE_BUCKET}/${JOB_TYPE}/${INPUT_PREFIX}
#rm -rf ${WEBDIR}

