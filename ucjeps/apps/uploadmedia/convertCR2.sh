#!/usr/bin/env bash

set -o errexit

CR2="$1"

F=$(echo "$CR2" | sed "s/\.CR2//i")
# make a jpg and a tif for each cr2
echo "converting ${CR2} to TIF AND JPG, and making a thumbnail"
#echo "/usr/bin/dcraw -w -c -compress zip \"${CR2}\" > \"${F}.TIF\""
#/usr/bin/dcraw -w -c -auto-orient -compress zip "${CR2}" > "${F}.TIF" 2>&1 &
echo convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF"
echo "convert \"${F}.JPG\" -quality 60 -thumbnail 20% ${F}.JPG.thumbnail.jpg"
convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF" 2>&1 &
convert -verbose "${CR2}" -auto-orient "${F}.JPG" 2>&1 &
TMPFILE=$(mktemp /tmp/ucjeps-archiving-temp.XXXXXX)
exiftool "${CR2}" > ${TMPFILE} &
wait
# now make the thumbnail from the JPG we just converted
convert "${F}.JPG" -quality 60 -thumbnail 20% ${F}.JPG.thumbnail.jpg &
for FORMAT in JPG TIF
do
  # if the image (TIF or JPG) is still landscape, rotate it as needed
  if [[ "1" == `convert "${F}.${FORMAT}" -format "%[fx:(w/h>1)?1:0]" info:` ]]
  then
     echo "${F}.${FORMAT}" is still Landscape. Checking EXIF data...
     grep Orientation ${TMPFILE}
     if $(perl -ne 'print if /^Orientation/' ${TMPFILE} | grep "Horizontal") ; then
        ROTATION="+270"
     else
        # default is +90, based on sampling
        ROTATION="+90"
     fi
     echo convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
  else
     echo "${F}.${FORMAT}" is Portrait.
     if $(perl -ne 'print if /^Orientation/' ${TMPFILE} | grep "Rotate 270 CW") ; then
       echo "... but exif data say we still have to flip it."
       ROTATION="+180"
       echo convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
       convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     fi
  fi

  ORIENTATION=`/cspace/merritt/batch/check_orientation_multi.sh "${F}.${FORMAT}"`
  if [[ ${ORIENTATION} =~ UpsideDown ]]
  then
    echo "looks like it is still upside down. rotating +180."
    echo "orientation: ${ORIENTATION}"
    echo convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
    time convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
  fi
  echo
done
rm ${TMPFILE}
wait
echo