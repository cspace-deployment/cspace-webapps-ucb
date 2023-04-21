#!/usr/bin/env bash

# nohup time ./check_cspace_images.sh ../check/tocheck2 /home/app_cspace/testimages/imgdiff/check > check.log 2>&1 &

JOB_FILE="$1"
BMU_DIR="/cspace/bmu/ucjeps"
IMAGE_SERVER=https://webapps-qa.cspace.berkeley.edu

if [[ ! -e ${BMU_DIR}/${JOB_FILE} ]]; then
  echo ${BMU_DIR}/${JOB_FILE} does not exist. please try again.
  exit 1
fi

JOB_PREFIX="${JOB_FILE%.processed.csv}"
TARGET=${BMU_DIR}/${JOB_PREFIX}

echo mkdir -p ${TARGET}
mkdir -p ${TARGET}
cut -f1,18 ${BMU_DIR}/${JOB_FILE} | grep -v blobCSID > ${TARGET}/images_to_check.csv

rm -f ${TARGET}/cspace_orientation.csv
touch ${TARGET}/cspace_orientation.csv

while IFS=$'\t' read -r FILENAME CSID
do
  echo ${FILENAME} ${CSID}
  CSID=${CSID//[$'\r\n']}
  IMAGE="/tmp/${FILENAME}"
  echo curl -s -S ${IMAGE_SERVER}/ucjeps/imageserver/blobs/${CSID}/derivatives/OriginalJpeg/content ${IMAGE}
  curl -s -S ${IMAGE_SERVER}/ucjeps/imageserver/blobs/${CSID}/derivatives/OriginalJpeg/content > ${IMAGE}
  FILENAME=`basename ${IMAGE}`
  F2="${IMAGE%.*}"
  ORIENTATION=`./check_orientation_multi.sh "${IMAGE}"`
  mv ${F2}.*.jpg ${TARGET}
  echo orientation: ${ORIENTATION}
  echo "$FILENAME $ORIENTATION" >> ${TARGET}/cspace_orientation.csv
  rm ${IMAGE}
done < ${TARGET}/images_to_check.csv

echo "<h3>Image Orientation Check for Job: ${JOB_PREFIX}</h3><h4>checked on `date`</h4>" > ${TARGET}/index.html
sort -k4,4 -k5n,5 ${TARGET}/cspace_orientation.csv | perl -pe '$i++; s#(.*?) (.*)#$i <img height="20px" src="\1.top.jpg">\1: \2<br/>#' >> ${TARGET}/index.html
