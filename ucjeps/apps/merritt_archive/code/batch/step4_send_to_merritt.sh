#!/usr/bin/env bash

# create a merritt manifest file and POST it to merrit ingest

# set -o errexit
echo "STEP: starting step4_send_to_merritt.sh"

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

RUN_DATE=`date +%Y%m%d%H%M`
TIFFS=$1
TIFFS_ERRORS="${TIFFS/tiffs/not_tiffs}"
TIFFS_QUEUED="${TIFFS/tiffs/queued}"
MANIFEST="${TIFFS/tiffs.csv/checkm}"
rm -f ${TIFFS_ERRORS} ; touch ${TIFFS_ERRORS}
rm -f ${TIFFS_QUEUED} ; touch ${TIFFS_QUEUED}

# these are set outside the script (i.e. by step1_set_env.sh)
# as environment variables
S3BUCKET="${S3BUCKET}"
SUBMITTER="${SUBMITTER}"
PROFILE="${PROFILE}"
MERRITT_INGEST=${MERRITT_INGEST}
collection_username="${COLLECTION_USERNAME}"
collection_password="${COLLECTION_PASSWORD}"

cp template.checkm ${MANIFEST}

for TIFF in `cut -f1 ${TIFFS}`
  do
    if [[ ! "${TIFF}" =~ TIF ]]; then
      echo "${TIFF} does not have 'TIF' in it; diverting to error queue"
      echo -e "${TIFF}\t${RUN_DATE}" >> ${TIFFS_ERRORS}
      continue
    fi
    #%fields | nfo:fileUrl | nfo:hashAlgorithm | nfo:hashValue | nfo:fileSize | nfo:fileLastModified | nfo:fileName | mrt:primaryIdentifier | mrt:localIdentifier | mrt:creator | mrt:title | mrt:date
    TITLE=`./check_db.sh "${TIFF}" metadata`

    BLOCKED=`./check_db.sh "${TIFF}" blocked | head -1`
    if [[ ! "${BLOCKED}" == "" ]]; then
      echo -e "${TIFF}\taccession number blocked: ${BLOCKED}\t${RUN_DATE}" >> ${TIFFS_ERRORS}
      echo -e "${TIFF}\taccession number blocked: ${BLOCKED}\t${RUN_DATE}"
      continue
    fi

    ALREADY_ARCHIVED=`./check_db.sh "${TIFF}" archived`
    if [[ ! "${ALREADY_ARCHIVED}" == "" ]]; then
      echo -e "${TIFF}\t$already archived as: ${ALREADY_ARCHIVED}\t${RUN_DATE}" >> ${TIFFS_ERRORS}
      continue
    fi
    # get rid of all vertical bars in the data
    TITLE=${TITLE/|/, }
    echo "title ${TIFF}: ${TITLE}"
    echo "${S3BUCKET}/${TIFF} | | | | | | | ${TIFF} | UC/JEPS Herbaria | ${TITLE} |" >> ${MANIFEST}
    echo -e "${TIFF}\t${RUN_DATE}" >> ${TIFFS_QUEUED}
done
echo "#%eof" >> ${MANIFEST}

echo "submitting to merritt, `date`"
cat << HERE
curl --verbose -u username:password
-F "file=@${MANIFEST}"
-F "type=container-batch-manifest"
-F "submitter=${SUBMITTER}"
-F "responseForm=xml"
-F "profile=${PROFILE}"
${MERRITT_INGEST}
HERE

curl --verbose -u ${collection_username}:${collection_password} \
-F "file=@${MANIFEST}" \
-F "type=container-batch-manifest" \
-F "submitter=${SUBMITTER}" \
-F "responseForm=xml" \
-F "profile=${PROFILE}" \
${MERRITT_INGEST}
