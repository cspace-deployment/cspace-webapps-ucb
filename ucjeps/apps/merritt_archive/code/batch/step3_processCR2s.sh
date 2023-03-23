#!/usr/bin/env bash

# copy cr2 file from merritt s3 bucket to local /tmp, convert to tiff, place in rtl 'in transit' bucket
# along the way, make a thumbnail and place it where it can be viewed from the web

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

RUN_DATE=`date +%Y-%m-%dT%H:%M`
IMAGE_FILE="$1"
OUTPUTDIR="$2"
WEBDIR=/var/www/static/thumbs
QUEUE_FILE="${IMAGE_FILE/cr2s/tiffs}"
QUEUE_ERRORS="${IMAGE_FILE/cr2s/not_queued}"
rm -f ${QUEUE_FILE} ; touch ${QUEUE_FILE}
rm -f ${QUEUE_ERRORS} ; touch ${QUEUE_ERRORS}

echo "converting CR2s in ${IMAGE_FILE}..."

SOURCE="archive"
OUTPUTPATH=${WEBDIR}/${SOURCE}/${OUTPUTDIR}
SIDEBAR=${OUTPUTPATH}/sidebar.html
PAGE=1
COUNTER=0
ITEMSPERPAGE=100
CSS='<head><link rel="stylesheet" href="/thumbs/specimen.css" type="text/css"></head>'

# make a thumbnail in the right place
if [ ! -d ${OUTPUTPATH} ]
then
  mkdir ${OUTPUTPATH}
  echo "creating ${OUTPUTPATH}..."
fi

# make index.html, wrapper for sidebar and image pages
cp ${WEBDIR}/index.template.html ${OUTPUTPATH}/index.html

echo "<html>${CSS}" > ${OUTPUTPATH}/page${PAGE}.html
echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page${PAGE}.html
echo "<html><ul>" > ${SIDEBAR}
echo "<li><a href="page${PAGE}.html" target="main">page ${PAGE}</a></li>" >> ${SIDEBAR}

while IFS=$'\t' read -r CR2 DATE
  do
    ((COUNTER++))
    if [[ ${COUNTER} -eq ITEMSPERPAGE ]]
    then
      ITEMS="${COUNTER}"
      COUNTER=0
      echo "</html>" >> ${OUTPUTPATH}/page${PAGE}.html
      ((PAGE++))
      echo "<li><a href="page${PAGE}.html" target="main">page ${PAGE}</a> [${ITEMS}]</li>" >> ${SIDEBAR}
      echo "<html>${CSS}" > ${OUTPUTPATH}/page${PAGE}.html
      echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page${PAGE}.html
    fi
    echo ">>>> page ${PAGE}, ${COUNTER}"
    HTML=${OUTPUTPATH}/page${PAGE}.html
    echo '<div class="specimen">' >> ${HTML}
    CR2_FILENAME=`basename -- "${CR2}"`
    echo "CR2_FILENAME ${CR2_FILENAME}"
    F=$(echo "${CR2_FILENAME}" | sed "s/\.CR2//i")
    # fetch the CR2 from S3
    echo "./ucjeps_cps3.sh \"$CR2\" ucjeps from <USER> <PASSWORD>"
    ./ucjeps_cps3.sh "${CR2}" ucjeps from "${MERRITT_USER}:${MERRITT_PASSWORD}" ${MERRITT_BUCKET} 2>&1
    # make a jpg and a tif for each cr2
    ./convertCR2.sh "/tmp/${CR2_FILENAME}" "${OUTPUTPATH}" "${SOURCE}"> ${OUTPUTPATH}/${F}.convert.txt 2>&1
    ./stats.sh "/tmp/${CR2_FILENAME}" "${CR2_FILENAME}" > ${OUTPUTPATH}/${F}.stats.txt &
    wait
    echo >> ${OUTPUTPATH}/${F}.stats.txt
    # put the converted file into S3 transient bucket
    echo "./ucjeps_cps3.sh \"${F}.TIF\" ucjeps to"
    ./ucjeps_cps3.sh "${F}.TIF" ucjeps to '' '' 2>&1
    if [[ "$?" == 0 ]] ; then
      IMG="${F}.thumbnail.jpg"
      echo -e "${F}.TIF\t${RUN_DATE}" >> ${QUEUE_FILE}
    else
      IMG="/thumbs/placeholder.thumbnail.jpg"
      echo -e "${CR2_FILENAME}\t${RUN_DATE}" >> ${QUEUE_ERRORS}
    fi
    echo "<a target=\"_blank\" href=\"${IMG}\"><img width=\"260px\" src=\"${IMG}\"></a>" >> ${HTML}
    echo "<br/><a target=\"_blank\" href=\"${F}.convert.txt\">${F}</a>" >> ${HTML}
    echo "<pre>" >> ${HTML}
    cat ${OUTPUTPATH}/${F}.stats.txt >> ${HTML}
    echo "</pre>" >> ${HTML}
    echo "</div>" >> ${HTML}
  # rm "/tmp/${CR2_FILENAME}"
done < ${IMAGE_FILE}
echo "</html>" >> ${HTML}
echo "</ul></html>" >> ${SIDEBAR}
