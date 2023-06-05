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
JOB_NAME="${FILE_NAME/.input.csv}"
JOB_TYPE=${FILE_NAME:0:3}
if [[ ! (${JOB_TYPE} == 'bmu' || ${JOB_TYPE} == 'arc') ]]; then
  echo "\"${JOB_TYPE}\" is not either bmu or arc; exiting."
  exit 1
fi

echo "starting ${INPUT_FILE} at `date`"
WEBDIR=$(mktemp -d /tmp/ucjeps-archiving.XXXXXX)

echo "WEBDIR $WEBDIR, FILE_NAME $FILE_NAME, JOB_TYPE $JOB_TYPE"

if [[ ${JOB_TYPE} == 'arc' ]]; then
 ./step2_filter.sh ${INPUT_PREFIX}.input.csv
 ./step3_processCR2s.sh ${INPUT_PREFIX}.cr2s.csv "${WEBDIR}"
 #./step4_send_to_merritt.sh ${INPUT_PREFIX}.tiffs.csv
elif [[ ${JOB_TYPE} == 'bmu' ]]; then
 ./step3_processBMU.sh ${INPUT_PREFIX}.input.csv "${WEBDIR}"
 ./step4_send_to_merritt.sh ${INPUT_PREFIX}.tiffs.csv
else
  echo "something bad happened to JOB_TYPE \"${JOB_TYPE}\""
  exit 1
fi

# count the number of lines in the various files involved
ls -tr ${INPUT_PREFIX}.*.csv | xargs wc -l

# WEBSITE_BUCKET is set as an env var in the pipeline
# update thumbnail viewer index.html
./make_job_index.sh "${WEBDIR}/${JOB_TYPE}/${JOB_NAME}" ${JOB_NAME} > "${WEBDIR}/${JOB_TYPE}/${JOB_NAME}/index.html"
# now sync job content to s3 website
echo aws s3 sync --quiet ${WEBDIR} ${WEBSITE_BUCKET}
aws s3 sync --quiet ${WEBDIR} ${WEBSITE_BUCKET}
# TODO: the top-level index.html page is rebuilt from s3 bucket content
# TODO: so we need to sync the new content to that bucket and then
# TODO: rebuild and resync the top-level index page
echo updating index.html and re-syncing website
./update_website.sh > "${WEBDIR}/index.html"
aws s3 sync --quiet ${WEBDIR} ${WEBSITE_BUCKET}
rm -rf ${WEBDIR}
echo "done with ${INPUT_FILE} at `date`"
