#!/usr/bin/env bash

set -xv
set -o errexit

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

CR2="$1"

F=$(echo "$CR2" | sed "s/\.CR2//i")
# make a jpg and a tif for each cr2
echo "converting ${CR2} to TIF AND JPG, and making a thumbnail"
echo /usr/bin/dcraw -v -w "${CR2}"
# we first convert to ppm...
${TIME_COMMAND} /usr/bin/dcraw -v -w "${CR2}"
# ...then to 8-bit tif
# nb: we do the compressing later after we finish fussing with the tif
echo convert -verbose ${F}.ppm -depth 8 "${F}.TIF"
${TIME_COMMAND} convert -verbose ${F}.ppm -depth 8 "${F}.TIF"
#echo convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF"
#convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF" 2>&1 &
TMPFILE="${F}.exifdata.txt"
echo exiftool "${CR2}" > ${TMPFILE}
${TIME_COMMAND} exiftool "${CR2}" > ${TMPFILE}
for FORMAT in TIF
do
  # if the image (TIF or JPG) is still landscape, rotate it as needed
  LANDSCAPE=`convert "${F}.${FORMAT}" -format "%[fx:(w/h>1)?1:0]" info:`
  if [[ "1" == "${LANDSCAPE}" ]]
  then
     echo "${F}.${FORMAT}" is still Landscape. Checking EXIF data...
     grep Orientation "${TMPFILE}"
     if [[ ! $(grep -e "^Orientation" "${TMPFILE}") =~ Horizontal ]]; then
        # default is +90, based on sampling
        ROTATION="+90"
     fi
     echo convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     ${TIME_COMMAND} convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
  else
     echo "${F}.${FORMAT}" is Portrait.
  fi

  ORIENTATION=`/cspace/merritt/batch/check_orientation_multi.sh "${F}.${FORMAT}"`
  echo "orientation: ${ORIENTATION}"
  echo "landscape: ${LANDSCAPE}"
  # if we already rotated a landscape image, don't bother checking its orientation
  if [[ ${ORIENTATION} =~ UpsideDown && "0" == "${LANDSCAPE}" ]]
  then
    echo "looks like it is still upside down. rotating +180."
    echo convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
    ${TIME_COMMAND} convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
  else
    echo "classifier says image is upright."
  fi
done
# compress the tif
${TIME_COMMAND} convert -verbose ${F}.TIF -compress zip "${F}.TIF"
# make the JPG from the TIF we just converted
echo convert -verbose "${F}.TIF" -auto-orient "${F}.JPG"
convert -verbose "${F}.TIF" -auto-orient "${F}.JPG"
# now make the thumbnail from the JPG
echo "convert \"${F}.JPG\" -quality 60 -thumbnail 20% \"${F}.thumbnail.jpg\""
${TIME_COMMAND} convert "${F}.JPG" -quality 60 -thumbnail 20% "${F}.thumbnail.jpg"
# we keep the exifdata file for now; another process takes care of it
# rm ${TMPFILE}
echo
