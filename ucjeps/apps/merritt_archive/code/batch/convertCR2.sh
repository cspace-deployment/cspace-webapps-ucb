#!/usr/bin/env bash

# set -xv
set -o errexit

# exif value for orientation are 1-8 with 1 meaning "Horizontal" (i.e. no rotation)
function detect_orientation() {
  case $1 in
    2)
    ROTATION='-flip horizontal'
    ;;
    3)
    ROTATION='-rotate 180'
    ;;
    4)
    ROTATION='-flip vertical'
    ;;
    5)
    ROTATION='-transpose'
    ;;
    6)
    ROTATION='-rotate 90'
    ;;
    7)
    ROTATION='-transverse'
    ;;
    8)
    ROTATION='-rotate 270'
    ;;
    *)
    ROTATION=''
    ;;
  esac
  echo "$ROTATION"
}

# os-specific command to format output of 'time'
export TIME_COMMAND="/usr/bin/time -f TIME,%E,%U,%S,%C"

CR2="$1"
DCRAW_PARMS="-a -b 1.2"

F=${CR2/.CR2/}
# make a jpg and a tif for each cr2
echo "converting ${CR2} to TIF AND JPG, and making a thumbnail"
# we first convert to ppm ...
${TIME_COMMAND} /usr/bin/dcraw -v "${DCRAW_PARMS}" "${CR2}"
#  ...then to 8-bit tif
# nb: we do the compressing later after we finish fussing with the tif
${TIME_COMMAND} convert -verbose ${F}.ppm -depth 8 "${F}.TIF"
rm ${F}.ppm
#echo convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF"
#convert -verbose "${CR2}" -auto-orient -depth 8 -compress zip "${F}.TIF" 2>&1 &
TMPFILE="${F}.exifdata.txt"
${TIME_COMMAND} exiftool "${CR2}" > ${TMPFILE} &
TMPFILE_NUMERIC="${F}.exifdata_numeric.txt"
${TIME_COMMAND} exiftool -n "${CR2}" > ${TMPFILE_NUMERIC} &
wait
for FORMAT in TIF
do
  # if the image (TIF or JPG) is still landscape, rotate it as needed
  LANDSCAPE=`convert "${F}.${FORMAT}" -format "%[fx:(w/h>1)?1:0]" info:`
  if [[ "1" == "${LANDSCAPE}" ]]
  then
     echo "${F}.${FORMAT}" is still Landscape. Checking EXIF data ...
     EXIF_ORIENTATION=$(grep -e "^Orientation" ${TMPFILE})
     echo "EXIF_ORIENTATION: ${EXIF_ORIENTATION}"
     ORIENTATION_NUMERIC=$(grep -e "^Orientation" ${TMPFILE_NUMERIC} | head -1 | perl -pe 's/.*(\d+).*/\1/')
     ROTATION=$(detect_orientation ${ORIENTATION_NUMERIC})
     echo "${ORIENTATION_NUMERIC} => ${ROTATION}"
     echo convert "${F}.${FORMAT}" ${ROTATION} "${F}.${FORMAT}"
     ${TIME_COMMAND} convert "${F}.${FORMAT}" ${ROTATION} "${F}.${FORMAT}"
  else
     echo "${F}.${FORMAT}" is Portrait.
  fi

  ORIENTATION=`/cspace/merritt/batch/check_orientation_multi.sh "${F}.${FORMAT}"`
  echo "detected orientation: ${F}.${FORMAT} = ${ORIENTATION}"
  echo "landscape: ${LANDSCAPE}"
  if [[ ${ORIENTATION} =~ UpsideDown ]]
  then
    echo "looks like it is still upside down. rotating +180."
    ${TIME_COMMAND} convert -rotate +180 "${F}.${FORMAT}" "${F}.${FORMAT}"
  else
    echo "classifier says image is upright."
  fi
done
# make the JPG from the TIF
${TIME_COMMAND} convert -verbose "${F}.TIF" "${F}.JPG"
# compress the tif
${TIME_COMMAND} convert -verbose ${F}.TIF -compress zip "${F}.TIF"
# we keep the exifdata file for now; another process takes care of it
# rm ${TMPFILE}
rm ${TMPFILE_NUMERIC}
echo
