#!/usr/bin/env bash

# once the image is archived, tidy up
# delete CR2 and IMAGE. copy JPG to a safe place.

# set -o errexit
echo "STEP: starting step5_tidy_up.sh"

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

COMPLETED=$1
COMPLETED_ERRORS="${COMPLETED/completed/completed_errors}"
rm -f ${COMPLETED_ERRORS} ; touch ${COMPLETED_ERRORS}

# this set outside the script (i.e. by step1_set_env.sh) as an environment variable
S3URI="${S3URI}"

for IMAGE in $(cut -f1 ${COMPLETED})
  do
    FILENAME_ONLY="${IMAGE/.*/}"
    ARCHIVED=$(./check_db.sh "${IMAGE}" archived)
    if [[ ! "${ARCHIVED}" == "" ]]; then
      # delete CR2
      aws s3 rm ${S3URI}/${FILENAME_ONLY}.CR2
      # delete TIF
      aws s3 rm ${S3URI}/${FILENAME_ONLY}.TIF
      # copy JPG to
      aws s3 cp ${S3URI}/${FILENAME_ONLY}.JPG s3://ucjeps-kept/JPGS/${FILENAME_ONLY}.JPG
    else
      echo -e "${IMAGE}\tnot showing as archived in solr core, skipping 'tidy up'\t${RUN_DATE}" >> ${COMPLETED_ERRORS}
      continue
    fi
done
