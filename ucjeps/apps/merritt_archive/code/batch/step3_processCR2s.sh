#!/usr/bin/env bash

# copy cr2 file from merritt s3 bucket to local /tmp, convert to tiff, place in rtl 'in transit' bucket
# along the way, make a thumbnail and place it where it can be viewed from the web

# set -o errexit
echo "STEP: starting step3_processCR2s.sh"

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

RUN_DATE=`date +%Y-%m-%dT%H:%M`
IMAGE_FILE="$1"

echo "converting CR2s in ${IMAGE_FILE} ..."

# name output files for next step
QUEUE_FILE="${IMAGE_FILE/cr2s/tiffs}"
QUEUE_ERRORS="${IMAGE_FILE/cr2s/not_queued}"
rm -f ${QUEUE_FILE} ; touch ${QUEUE_FILE}
rm -f ${QUEUE_ERRORS} ; touch ${QUEUE_ERRORS}

# make thumbnails in the right place
JOB=$(basename -- "${IMAGE_FILE}")
OUTPUTDIR="${JOB/.cr2s.csv/}"
WEBDIR="$2"
SOURCE="arc"
OUTPUTPATH=${WEBDIR}/${SOURCE}/${OUTPUTDIR}
rm -rf ${WEBDIR}
echo "creating ${OUTPUTPATH}  ..."
mkdir -p ${OUTPUTPATH}
PAGE=1
COUNTER=1
ITEMSPERPAGE=100
CSS='<head><link rel="stylesheet" href="/specimen.css" type="text/css"></head>'

echo "<html>${CSS}" > ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
echo "<div class="row">" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
echo "</div>" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
echo "<div class="row">" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html

while IFS=$'\t' read -r CR2 DATE
  do
    ERRORS=0
    ((COUNTER++))
    if [[ ${COUNTER} -eq ${ITEMSPERPAGE} ]]
    then
      ITEMS="${COUNTER}"
      COUNTER=1
      echo "</html>" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
      ((PAGE++))
      echo "<html>${CSS}" > ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
      echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
    fi
    echo ">>>> CR2_FILENAME ${CR2_FILENAME}, page ${PAGE}, ${COUNTER}"
    HTML=${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
    echo '<div class="specimen">' >> ${HTML}
    CR2_FILENAME=`basename -- "${CR2}"`
    FNAME_ONLY=$(echo "${CR2_FILENAME}" | sed "s/\.CR2//i")
    # fetch the CR2 from S3
    echo "./ucjeps_cps3.sh \"${CR2_FILENAME}\" ucjeps from"
    ./ucjeps_cps3.sh "${CR2_FILENAME}" ucjeps from 2>&1
    [[ $? -ne 0 ]] && ERRORS=1
    if [[ $ERRORS -eq 0 ]] ; then
      # make a jpg and a tif for each cr2
      echo "fetch from s3 ok, converting /tmp/${CR2_FILENAME} ..."
      ${TIME_COMMAND} ./convertCR2.sh "/tmp/${CR2_FILENAME}"
      # preserve the exifdata (put into a temp file by convertCR2.sh)
      cat "/tmp/${FNAME_ONLY}.exifdata.txt"  >> ${OUTPUTPATH}/${FNAME_ONLY}.convert.txt
      # dump the convert log into this message stream
      # cat ${OUTPUTPATH}/${FNAME_ONLY}.convert.txt
      [[ $? -ne 0 ]] && ERRORS=1
      ./stats.sh "/tmp/${CR2_FILENAME}" "${CR2_FILENAME}" > ${OUTPUTPATH}/${FNAME_ONLY}.stats.txt
      echo >> ${OUTPUTPATH}/${FNAME_ONLY}.stats.txt
      ${TIME_COMMAND} convert "/tmp/${FNAME_ONLY}.JPG" -quality 60 -thumbnail 20% "${OUTPUTPATH}/${FNAME_ONLY}.thumbnail.jpg"
      # put the converted file into S3 transient bucket
      echo "./ucjeps_cps3.sh \"${FNAME_ONLY}.TIF\" ucjeps to"
      ${TIME_COMMAND} ./ucjeps_cps3.sh "${FNAME_ONLY}.TIF" ucjeps to 2>&1
      [[ $? -ne 0 ]] && ERRORS=1
    fi
    if [[ $ERRORS -eq 0 ]] ; then
      IMG="${FNAME_ONLY}.thumbnail.jpg"
      IMG2="${FNAME_ONLY}.original.thumbnail.jpg"
      exiftool -ThumbnailImage -b "/tmp/${CR2_FILENAME}" > "/tmp/${IMG2}"
      cp "/tmp/${IMG2}" "${OUTPUTPATH}/${IMG2}"
      echo -e "${FNAME_ONLY}.TIF\t${RUN_DATE}" >> ${QUEUE_FILE}
    else
      IMG="/placeholder.thumbnail.jpg"
      IMG2="/placeholder.thumbnail.jpg"
      echo -e "${CR2_FILENAME}\t${RUN_DATE}" >> ${QUEUE_ERRORS}
      echo "Errors found in S3 transfers or Imagemagick conversion"
    fi
    echo "<a target=\"_blank\" href=\"${IMG}\"><img width=\"260px\" src=\"${IMG}\"></a>" >> ${HTML}
    echo "<a target=\"_blank\" href=\"${IMG2}\"><img src=\"${IMG2}\"></a>" >> ${HTML}
    echo "<br/><a target=\"_blank\" href=\"${FNAME_ONLY}.convert.txt\">${FNAME_ONLY}</a>" >> ${HTML}
    echo "<pre>" >> ${HTML}
    cat ${OUTPUTPATH}/${FNAME_ONLY}.stats.txt >> ${HTML}
    rm ${OUTPUTPATH}/${FNAME_ONLY}.stats.txt
    echo "</pre>" >> ${HTML}
    echo "</div>" >> ${HTML}
    echo rm /tmp/${FNAME_ONLY}.*
    rm /tmp/${FNAME_ONLY}.*
done < ${IMAGE_FILE}
echo "</html>" >> ${HTML}
