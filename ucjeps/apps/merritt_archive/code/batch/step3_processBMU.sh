#!/usr/bin/env bash

# get TIF from bmu queue, place in rtl 'in transit' bucket
# along the way, make a thumbnail and place it where it can be viewed from the web

# set -o errexit
echo "STEP: starting step3_processBMU.sh"

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

RUN_DATE=`date +%Y-%m-%dT%H:%M`
IMAGE_FILE="$1"

echo "getting BMU TIFs from ${IMAGE_FILE} ..."

# name output files for next step
QUEUE_FILE="${IMAGE_FILE/input/tiffs}"
QUEUE_ERRORS="${IMAGE_FILE/input/not_queued}"
rm -f ${QUEUE_FILE} ; touch ${QUEUE_FILE}
rm -f ${QUEUE_ERRORS} ; touch ${QUEUE_ERRORS}

# make thumbnails in the right place
JOB=$(basename -- "${IMAGE_FILE}")
WEBDIR="$2"
SOURCE="bmu"
OUTPUTDIR="${JOB/.input.csv/}"
OUTPUTPATH=${WEBDIR}/${SOURCE}/${OUTPUTDIR}
rm -rf ${WEBDIR}
echo "creating ${OUTPUTPATH}  ..."
mkdir -p ${OUTPUTPATH}
PAGE=1
COUNTER=0
ITEMSPERPAGE=100
CSS='<head><link rel="stylesheet" href="/specimen.css" type="text/css"></head>'

echo "<html>${CSS}" > ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
echo "<div class="row">" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
echo "</div>" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
echo "<div class="row">" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html

echo "starting reading ${IMAGE_FILE}"
while IFS=$'\t' read -r TIF
  do
    ERRORS=0
    if [[ ${COUNTER} -eq ${ITEMSPERPAGE} ]]
    then
      ITEMS="${COUNTER}"
      COUNTER=0
      echo "</html>" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
      ((PAGE++))
      echo "<html>${CSS}" > ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
      echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
    fi
    ((COUNTER++))
    echo ">>>> TIF ${TIF}, page ${PAGE}, ${COUNTER}"
    HTML=${OUTPUTPATH}/page$(printf "%02d" ${PAGE}).html
    echo '<div class="specimen">' >> ${HTML}
    FNAME_ONLY=${TIF/.TIF/}
    # fetch the TIF from the BMU S3 bucket
    echo /var/www/ucjeps/uploadmedia/cps3.sh "${TIF}" ucjeps from
    /var/www/ucjeps/uploadmedia/cps3.sh "${TIF}" ucjeps from
    [[ $? -ne 0 ]] && ERRORS=1
    if [[ $ERRORS -eq 0 ]] ; then
      # make a thumbnail jpg for each TIF
      echo "fetch from s3 ok, converting /tmp/${TIF} ..."
      ./stats.sh "/tmp/${TIF}" "${TIF}" > "${OUTPUTPATH}/${FNAME_ONLY}.stats.txt"
      echo "convert \"${TIF}\" -quality 60 -thumbnail 20% \"${OUTPUTPATH}/${FNAME_ONLY}.thumbnail.jpg\""
      ${TIME_COMMAND} convert "/tmp/${TIF}" -quality 60 -thumbnail 20% "${OUTPUTPATH}/${FNAME_ONLY}.thumbnail.jpg"
      # put the TIF file from the BMU cache into S3 transient bucket
      echo "./ucjeps_cps3.sh \"${TIF}\" ucjeps to"
      ./ucjeps_cps3.sh "${TIF}" ucjeps to 2>&1
      [[ $? -ne 0 ]] && ERRORS=1
    fi
    if [[ $ERRORS -eq 0 ]] ; then
      IMG="${FNAME_ONLY}.thumbnail.jpg"
      echo -e "${TIF}\t${RUN_DATE}" >> ${QUEUE_FILE}
    else
      IMG="/placeholder.thumbnail.jpg"
      echo -e "${TIF}\t${RUN_DATE}" >> ${QUEUE_ERRORS}
      echo "Errors found in S3 transfers or Imagemagick conversion"
    fi
    echo "<a target=\"_blank\" href=\"${IMG}\"><img width=\"260px\" src=\"${IMG}\"></a>" >> ${HTML}
    # echo "<br/><a target=\"_blank\" href=\"${FNAME_ONLY}.convert.txt\">${FNAME_ONLY}</a>" >> ${HTML}
    echo "<pre>" >> ${HTML}
    cat "${OUTPUTPATH}/${FNAME_ONLY}.stats.txt" >> ${HTML}
    rm "${OUTPUTPATH}/${FNAME_ONLY}.stats.txt"
    echo "</pre>" >> ${HTML}
    echo "</div>" >> ${HTML}
done < ${IMAGE_FILE}
echo "</html>" >> ${HTML}
