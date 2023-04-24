#!/usr/bin/env bash

# get TIF from bmu queue, place in rtl 'in transit' bucket
# along the way, make a thumbnail and place it where it can be viewed from the web

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

RUN_DATE=`date +%Y-%m-%dT%H:%M`
IMAGE_FILE="$1"

echo "getting BMU TIFs from ${IMAGE_FILE}..."

# name output files for next step
QUEUE_FILE="${IMAGE_FILE/input/tiffs}"
QUEUE_ERRORS="${IMAGE_FILE/input/not_queued}"
rm -f ${QUEUE_FILE} ; touch ${QUEUE_FILE}
rm -f ${QUEUE_ERRORS} ; touch ${QUEUE_ERRORS}

# make thumbnails in the right place
JOB=$(basename -- "${IMAGE_FILE}")
WEBDIR="$2"
SOURCE="bmu"
OUTPUTPATH=${WEBDIR}/${SOURCE}/${OUTPUTDIR}
rm -rf ${WEBDIR}
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

while IFS=$'\t' read -r TIF DATE
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
    echo ">>>> TIF ${TIF}, page ${PAGE}, ${COUNTER}"
    HTML=${OUTPUTPATH}/page${PAGE}.html
    echo '<div class="specimen">' >> ${HTML}
    F=${TIF/.TIF/}
    # fetch the TIF from the BMU S3 bucket
    echo /var/www/ucjeps/uploadmedia/cps3.sh "${TIF}" ucjeps from
    /var/www/ucjeps/uploadmedia/cps3.sh "${TIF}" ucjeps from
    [[ $? -ne 0 ]] && ERRORS=1
    if [[ $ERRORS -eq 0 ]] ; then
      # make a jpg and a tif for each TIF
      echo "fetch from s3 ok, converting /tmp/${TIF}..."
      ./stats.sh "/tmp/${TIF}" "${TIF}" > ${OUTPUTPATH}/${F}.stats.txt &
      wait
      echo >> ${OUTPUTPATH}/${F}.stats.txt
      # now make the thumbnail from the TIF we just converted
      echo "convert \"${TIF}\" -quality 60 -thumbnail 20% \"${OUTPUTPATH}/${F}.thumbnail.jpg\""
      convert "/tmp/${TIF}" -quality 60 -thumbnail 20% "${OUTPUTPATH}/${F}.thumbnail.jpg"
      # put the copied file into S3 transient bucket
      echo "./ucjeps_cps3.sh \"${TIF}\" ucjeps to"
      ./ucjeps_cps3.sh "${TIF}" ucjeps to '' '' 2>&1
      [[ $? -ne 0 ]] && ERRORS=1
    fi
    if [[ $ERRORS -eq 0 ]] ; then
      IMG="${F}.thumbnail.jpg"
      echo -e "${TIF}\t${RUN_DATE}" >> ${QUEUE_FILE}
    else
      IMG="/thumbs/placeholder.thumbnail.jpg"
      echo -e "${TIF}\t${RUN_DATE}" >> ${QUEUE_ERRORS}
      echo "Errors found in S3 transfers or Imagemagick conversion"
    fi
    echo "<a target=\"_blank\" href=\"${IMG}\"><img width=\"260px\" src=\"${IMG}\"></a>" >> ${HTML}
    echo "<br/><a target=\"_blank\" href=\"${F}.convert.txt\">${F}</a>" >> ${HTML}
    echo "<pre>" >> ${HTML}
    cat ${OUTPUTPATH}/${F}.stats.txt >> ${HTML}
    rm ${OUTPUTPATH}/${F}.stats.txt
    echo "</pre>" >> ${HTML}
    echo "</div>" >> ${HTML}
done < ${IMAGE_FILE}
echo "</html>" >> ${HTML}
echo "</ul></html>" >> ${SIDEBAR}
