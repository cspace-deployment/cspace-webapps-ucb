#!/usr/bin/env bash

# set -o errexit
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
touch ${INPUT_PREFIX}.inprogress.csv
WEBDIR=$(mktemp -d /tmp/ucjeps-archiving.XXXXXX)

echo "WEBDIR $WEBDIR, FILE_NAME $FILE_NAME, JOB_TYPE $JOB_TYPE"

if [[ ${JOB_TYPE} == 'arc' ]]; then
 ./step2_filter.sh ${INPUT_PREFIX}.input.csv 2>&1
 ./step3_processCR2s.sh ${INPUT_PREFIX}.cr2s.csv "${WEBDIR}" 2>&1
 ./step4_send_to_merritt.sh ${INPUT_PREFIX}.tiffs.csv 2>&1
elif [[ ${JOB_TYPE} == 'bmu' ]]; then
 ./step3_processBMU.sh ${INPUT_PREFIX}.input.csv "${WEBDIR}" 2>&1
 ./step4_send_to_merritt.sh ${INPUT_PREFIX}.tiffs.csv 2>&1
else
  echo "something bad happened to JOB_TYPE \"${JOB_TYPE}\""
  exit 1
fi

# count the number of lines in the various files involved
ls -tr ${INPUT_PREFIX}.*.csv | xargs wc -l

# WEBSITE_BUCKET is set as an env var in the pipeline
# update thumbnail viewer index.html
./make_job_index.sh "${WEBDIR}/${JOB_TYPE}/${JOB_NAME}" ${JOB_NAME} > "${WEBDIR}/${JOB_TYPE}/${JOB_NAME}/index.html" 2>&1
# now sync job content to s3 website
echo aws s3 sync --no-progress ${WEBDIR} ${WEBSITE_BUCKET} 2>&1
aws s3 sync --no-progress ${WEBDIR} ${WEBSITE_BUCKET} 2>&1
# TODO: the top-level index.html page is rebuilt from s3 bucket content
# TODO: so we need to sync the new content to that bucket and then
# TODO: rebuild and resync the top-level index page
echo updating index.html and re-syncing website
./update_website.sh > "${WEBDIR}/index.html" 2>&1
aws s3 sync --no-progress ${WEBDIR} ${WEBSITE_BUCKET} 2>&1
rm -rf ${WEBDIR}
rm -f ${INPUT_PREFIX}.inprogress.csv
# copy the jobs files to s3 for future reference
aws s3 cp --no-progress --exclude "*" --include "${JOB_NAME}.*" --recursive ../jobs/ s3://cspace-merritt-in-transit-prod/jobs/
echo "done with ${INPUT_FILE} at `date`"
