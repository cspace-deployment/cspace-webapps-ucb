#!/bin/bash

# these better be here!
source ~/.profile
source ${HOME}/venv/bin/activate

CR2="$1"

fileinfo $CR2
echo

F=$(echo "$CR2" | sed "s/\.CR2//i")
# make a jpg and a tif for each cr2
for FORMAT in JPG TIF
do
  echo "converting ${CR2} to ${F}.${FORMAT}"
  convert -verbose "${CR2}" "${F}.${FORMAT}" 2>&1
  echo ">>>> after initial conversion"
  fileinfo "${F}.${FORMAT}"
  echo
  # if the image (TIF or JPG) is still landscape, rotate it 90 CCW
  if [[ "1" == `convert "${F}.${FORMAT}" -format "%[fx:(w/h>1)?1:0]" info:` ]]
  then
    # try to figure out which way to rotate the landscape image
     ROTATION="-90"
     if [[ `exiftool "${CR2}" | grep "Rotate 90 CW"` ]]
     then
        ROTATION="+90"
     fi
     echo "${F}.${FORMAT}" is Landscape, rotating ${ROTATION}
     echo convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     convert -rotate ${ROTATION} "${F}.${FORMAT}" "${F}.${FORMAT}"
     fileinfo "${F}.${FORMAT}"
     echo
  fi
done
echo