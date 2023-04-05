#!/usr/bin/env bash

# copy cr2 file from merritt s3 bucket to local /tmp, convert to tiff, place in rtl 'in transit' bucket
# along the way, make a thumbnail and place it where it can be viewed from the web

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

RUN_DATE=`date +%Y-%m-%dT%H:%M`
IMAGE_FILE="$1"

echo "converting CR2s in ${IMAGE_FILE}..."

# name output files for next step
QUEUE_FILE="${IMAGE_FILE/cr2s/tiffs}"
QUEUE_ERRORS="${IMAGE_FILE/cr2s/not_queued}"
rm -f ${QUEUE_FILE} ; touch ${QUEUE_FILE}
rm -f ${QUEUE_ERRORS} ; touch ${QUEUE_ERRORS}

# make thumbnails in the right place
JOB=$(basename -- "${IMAGE_FILE}")
OUTPUTDIR="${JOB/.cr2s.csv/}"
WEBDIR=$(mktemp -d /tmp/ucjeps-archiving.XXXXXX)
SOURCE="archive"
OUTPUTPATH=${WEBDIR}/${SOURCE}/${OUTPUTDIR}
if [[ -d ${OUTPUTPATH} ]] ; then
  rm -rf ${OUTPUTPATH}
fi
echo "creating ${OUTPUTPATH}..."
mkdir -p ${OUTPUTPATH}
SIDEBAR=${OUTPUTPATH}/sidebar.html
PAGE=1
COUNTER=0
ITEMSPERPAGE=100
CSS='<head><link rel="stylesheet" href="/thumbs/specimen.css" type="text/css"></head>'

# make index.html, wrapper for sidebar and image pages
cp ../web/index.template.html ${OUTPUTPATH}/index.html

echo "<html>${CSS}" > ${OUTPUTPATH}/page${PAGE}.html
echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page${PAGE}.html
echo "<html><ul>" > ${SIDEBAR}
echo "<li><a href="page${PAGE}.html" target="main">page ${PAGE}</a></li>" >> ${SIDEBAR}

while IFS=$'\t' read -r CR2 DATE
  do
    ERRORS=0
    ((COUNTER++))
    if [[ ${COUNTER} -eq ${ITEMSPERPAGE} ]]
    then
      ITEMS="${COUNTER}"
      COUNTER=0
      echo "</html>" >> ${OUTPUTPATH}/page${PAGE}.html
      ((PAGE++))
      echo "<li><a href="page${PAGE}.html" target="main">page ${PAGE}</a> [${ITEMS}]</li>" >> ${SIDEBAR}
      echo "<html>${CSS}" > ${OUTPUTPATH}/page${PAGE}.html
      echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page${PAGE}.html
    fi
    echo ">>>> CR2_FILENAME ${CR2_FILENAME}, page ${PAGE}, ${COUNTER}"
    HTML=${OUTPUTPATH}/page${PAGE}.html
    echo '<div class="specimen">' >> ${HTML}
    CR2_FILENAME=`basename -- "${CR2}"`
    F=$(echo "${CR2_FILENAME}" | sed "s/\.CR2//i")
    # fetch the CR2 from S3
    echo "./ucjeps_cps3.sh \"$CR2\" ucjeps from <USER> <PASSWORD> <BUCKET>"
    ./ucjeps_cps3.sh "${CR2}" ucjeps from "${MERRITT_USER}:${MERRITT_PASSWORD}" ${MERRITT_BUCKET} 2>&1
    [[ $? -ne 0 ]] && ERRORS=1
    if [[ $ERRORS -eq 0 ]] ; then
      # make a jpg and a tif for each cr2
      echo "fetch from s3 ok, converting /tmp/${CR2_FILENAME}..."
      ./convertCR2.sh "/tmp/${CR2_FILENAME}" "${OUTPUTPATH}" > ${OUTPUTPATH}/${F}.convert.txt 2>&1
      [[ $? -ne 0 ]] && ERRORS=1
      ./stats.sh "/tmp/${CR2_FILENAME}" "${CR2_FILENAME}" > ${OUTPUTPATH}/${F}.stats.txt &
      wait
      echo >> ${OUTPUTPATH}/${F}.stats.txt
      # put the converted file into S3 transient bucket
      echo "./ucjeps_cps3.sh \"${F}.TIF\" ucjeps to"
      ./ucjeps_cps3.sh "${F}.TIF" ucjeps to '' '' 2>&1
      [[ $? -ne 0 ]] && ERRORS=1
    fi
    if [[ $ERRORS -eq 0 ]] ; then
      IMG="${F}.thumbnail.jpg"
      echo -e "${F}.TIF\t${RUN_DATE}" >> ${QUEUE_FILE}
    else
      IMG="/thumbs/placeholder.thumbnail.jpg"
      echo -e "${CR2_FILENAME}\t${RUN_DATE}" >> ${QUEUE_ERRORS}
      echo "Errors found in S3 transfers or Imagemagick conversion"
    fi
    echo "<a target=\"_blank\" href=\"${IMG}\"><img width=\"260px\" src=\"${IMG}\"></a>" >> ${HTML}
    echo "<br/><a target=\"_blank\" href=\"${F}.convert.txt\">${F}</a>" >> ${HTML}
    echo "<pre>" >> ${HTML}
    cat ${OUTPUTPATH}/${F}.stats.txt >> ${HTML}
    echo "</pre>" >> ${HTML}
    echo "</div>" >> ${HTML}
  rm "/tmp/${CR2_FILENAME}"
done < ${IMAGE_FILE}
echo "</html>" >> ${HTML}
echo "</ul></html>" >> ${SIDEBAR}

# WEBSITE_BUCKET is set as an env var in the pipeline
aws s3 sync ${WEBDIR} ${WEBSITE_BUCKET}
#rm -rf ${WEBDIR}
