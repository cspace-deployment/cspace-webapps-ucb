#!/usr/bin/env bash

set -o errexit

CR2="$1"

F=$(echo "$CR2" | sed "s/\.CR2//i")
# make a jpg and a tif for each cr2
echo "converting ${CR2} to TIF AND JPG, and making a thumbnail"
#echo "/usr/bin/dcraw -w -c -compress zip \"${CR2}\" > \"${F}.TIF\""
#/usr/bin/dcraw -w -c -auto-orient -compress zip "${CR2}" > "${F}.TIF" 2>&1 &
echo convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF"
convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF" 2>&1 &
convert -verbose "${CR2}" -auto-orient "${F}.JPG" 2>&1 &
TMPFILE="${F}.convert.txt"
# TMPFILE=$(mktemp /tmp/ucjeps-archiving-temp.XXXXXX)
exiftool "${CR2}" > ${TMPFILE} &
wait
for FORMAT in JPG TIF
do
  # if the image (TIF or JPG) is still landscape, rotate it as needed
  LANDSCAPE=`convert "${F}.${FORMAT}" -format "%[fx:(w/h>1)?1:0]" info:`
  if [[ "1" == "${LANDSCAPE}" ]]
  then
     echo "${F}.${FORMAT}" is still Landscape. Checking EXIF data...
     grep Orientation "${TMPFILE}"
     if [[ $(grep -e "^Orientation" "${TMPFILE}") =~ Horizontal ]]; then
        ROTATION="+270"
     else
        # default is +90, based on sampling
        ROTATION="+90"
     fi
     echo convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
  else
     echo "${F}.${FORMAT}" is Portrait.
  fi

  ORIENTATION=`/cspace/merritt/batch/check_orientation_multi.sh "${F}.${FORMAT}"`
  echo "orientation: ${ORIENTATION}"
  # if we already rotated a landscape image, don't bother checking its orientation
  if [[ ${ORIENTATION} =~ UpsideDown && "0" == "${LANDSCAPE}" ]]
  then
    echo "looks like it is still upside down. rotating +180."
    echo convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
    time convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
  else
    echo "classifier says image is upright."
  fi
done
# now make the thumbnail from the JPG we just converted
echo "convert \"${F}.JPG\" -quality 60 -thumbnail 20% \"${F}.thumbnail.jpg\""
convert "${F}.JPG" -quality 60 -thumbnail 20% "${F}.thumbnail.jpg"
echo ">>>>  EXIFDATA <<<<"
cat ${TMPFILE}
rm ${TMPFILE}
echo
