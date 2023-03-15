#!/usr/bin/env bash

set -o errexit

# these better be here!
source ~/.profile
source ${HOME}/venv/bin/activate

CR2="$1"
JOB=`basename -- "$2"`
SOURCE="$3"
WEBDIR=/var/www/static/thumbs

fileinfo ${CR2}
echo "=============== exiftool info ================="
exiftool ${CR2}
echo 

F=$(echo "$CR2" | sed "s/\.CR2//i")
# make a jpg and a tif for each cr2
echo "converting ${CR2} to TIF AND JPG"
#echo "/usr/bin/dcraw -w -c -compress zip \"${CR2}\" > \"${F}.TIF\""
#/usr/bin/dcraw -w -c -auto-orient -compress zip "${CR2}" > "${F}.TIF" 2>&1 &
echo "convert -verbose \"${CR2}\" -auto-orient -depth 8 -compress zip \"${F}.TIF\""
convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF" 2>&1
# convert -verbose "${CR2}" -auto-orient "${F}.JPG" 2>&1 &
# wait
# for now, we only concern ourselves with TIFs. no fussing with JPGs
#for FORMAT in JPG TIF
for FORMAT in TIF
do
  echo "========= after initial conversion ============"
  fileinfo "${F}.${FORMAT}"
  echo
  # if the image (TIF or JPG) is still landscape, rotate it as needed
  if [[ "1" == `convert "${F}.${FORMAT}" -format "%[fx:(w/h>1)?1:0]" info:` ]]
  then
    # try to figure out which way to rotate the landscape image
     if [[ `exiftool "${CR2}" | grep "Rotate 90 CCW"` ]] ; then
        ROTATION="-90"
     elif [[ `exiftool "${CR2}" | grep "Rotate 270 CW"` ]] ; then
        ROTATION="+270"
     elif [[ `exiftool "${CR2}" | grep "Rotate 90 CW"` ]] ; then
        ROTATION="+90"
     else
        # default is +90, based on sampling
        ROTATION="+90"
     fi
     echo "${F}.${FORMAT}" is Landscape, rotating ${ROTATION}
     echo convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     echo "============= after rotation =================="
     fileinfo "${F}.${FORMAT}"
     echo
  else
     echo "${F}.${FORMAT} is Portrait, no further rotation necessary"
  fi
  # desperate hack
  if [[ `exiftool "${CR2}" | grep "Rotate 90 CW"` && `exiftool "${CR2}" | grep "Rotate 270 CW"` ]] ; then
     ROTATION="+180"
     echo Desperately rotating +180: convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
  fi
  fileinfo "${F}.${FORMAT}"
  echo
done
# make a thumbnail in the right place
if [ ! -d ${WEBDIR}/${SOURCE}/${JOB} ]
then
  mkdir ${WEBDIR}/${SOURCE}/${JOB}
fi
F2=`basename ${F}.TIF`
F2="${F2%.*}"
echo "creating thumbnail..."
echo "convert \"${F}.TIF\" -quality 60 -thumbnail 20% ${WEBDIR}/${SOURCE}/${JOB}/${F2}.thumbnail.jpg"
convert "${F}.TIF" -quality 60 -thumbnail 20% ${WEBDIR}/${SOURCE}/${JOB}/${F2}.thumbnail.jpg &
echo
