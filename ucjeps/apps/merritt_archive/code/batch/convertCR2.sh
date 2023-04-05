#!/usr/bin/env bash

set -o errexit

# these better be here!
source ~/.profile
source ${HOME}/venv/bin/activate

CR2="$1"
JOB=`basename -- "$2"`
OUTPUTPATH="$3"

echo "=============== exiftool info ================="
exiftool ${CR2} || exit 1
echo

F=$(echo "$CR2" | sed "s/\.CR2//i")
# make a jpg and a tif for each cr2
echo "converting ${CR2} to TIF..."
#/usr/bin/dcraw -w -c -auto-orient -compress zip "${CR2}" > "${F}.TIF" 2>&1 &
echo "convert -verbose \"${CR2}\" -auto-orient -depth 8 -compress zip \"${F}.TIF\""
time convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF" || exit 1
# convert -verbose "${CR2}" -auto-orient "${F}.JPG" 2>&1 &
# wait

FORMAT="TIF"
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
   echo "${F}.${FORMAT}" is still Landscape, rotating ${ROTATION}
   echo convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
   time convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
else
   echo "${F}.${FORMAT} is Portrait, no further rotation necessary"
fi

orientation=`./check_orientation.sh "${F}.${FORMAT}"`
if [[ ${orientation} =~ UpsideDown ]]
then
  echo "looks like it's still upside down. rotating +180."
  echo "orientation: ${orientation}"
  echo convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
  time convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
fi
F2=`basename ${F}.TIF`
F2="${F2%.*}"
echo "creating thumbnail..."
echo "convert \"${F}.TIF\" -quality 60 -thumbnail 20% \"${OUTPUTPATH}/${F2}.thumbnail.jpg\""
time convert "${F}.TIF" -quality 60 -thumbnail 20% "${OUTPUTPATH}/${F2}.thumbnail.jpg" &
echo
