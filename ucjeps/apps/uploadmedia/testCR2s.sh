#!/bin/bash

# these better be here!
source ~/.profile
source ${HOME}/venv/bin/activate

CR2file="$1"
RUNDIR=/var/www/ucjeps/uploadmedia
WEBDIR=/var/www/static/thumbs
OUTPUTDIR="$2"
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
fi

# add a link to the start page for archive jobs
echo "<li><a target=\"_blank\" href=\"${OUTPUTDIR}\">${OUTPUTDIR}</a> [`cat ${CR2file} | wc -l`]" >> ${WEBDIR}/${SOURCE}/index.html
cp ${WEBDIR}/${SOURCE}/index.template.html ${OUTPUTPATH}/index.html

echo "<html>${CSS}" > ${OUTPUTPATH}/page${PAGE}.html
echo "<h3>Page ${PAGE}</h3>" >> ${OUTPUTPATH}/page${PAGE}.html
echo "<html><ul>" > ${SIDEBAR}
echo "<li><a href="page${PAGE}.html" target="main">page ${PAGE}</a></li>" >> ${SIDEBAR}

for CR2 in `cat ${CR2file}`
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
    F=$(echo "$CR2" | sed "s/\.CR2//i")
    # fetch the CR2 from S3
    echo "${RUNDIR}/cps3.sh \"$CR2\" ucjeps from"
    ${RUNDIR}/cps3.sh "$CR2" ucjeps from 2>&1
    # make a jpg and a tif for each cr2
    ./convertCR2.sh "/tmp/${CR2}" "${OUTPUTPATH}" "${SOURCE}"> ${OUTPUTPATH}/${F}.convert.txt 2>&1 &
    ./stats.sh "/tmp/$CR2" "${CR2}" > ${OUTPUTPATH}/${F}.stats.txt &
    wait
    echo >> ${OUTPUTPATH}/${F}.stats.txt
    # put the converted file back into S3
    for FORMAT in JPG TIF
    do
      echo "${RUNDIR}/cps3.sh \"${F}.${FORMAT}\" ucjeps to"
      ${RUNDIR}/cps3.sh "${F}.${FORMAT}" ucjeps to 2>&1 &
    done
    ./stats.sh "/tmp/${F}.JPG" "${F}.JPG" >> ${OUTPUTPATH}/${F}.stats.txt
    IMG="${F}.thumbnail.jpg"
    echo "<a target=\"_blank\" href=\"${IMG}\"><img width=\"200px\" src=\"${IMG}\"></a>" >> ${HTML}
    echo "<br/><a target=\"_blank\" href=\"${F}.convert.txt\">${F}</a>" >> ${HTML}
    echo "<pre>" >> ${HTML}
    cat ${OUTPUTPATH}/${F}.stats.txt >> ${HTML}
    echo "</pre>" >> ${HTML}
    echo "</div>" >> ${HTML}
  rm "/tmp/${CR2}"
done
echo "</html>" >> ${HTML}
echo "</ul></html>" >> ${SIDEBAR}
