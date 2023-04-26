#!/usr/bin/env bash

IMAGE="$1"

function wrap_orientation() {
  echo "$1 $2 $3 : $4"
}

if [[ ! -e "${IMAGE}" ]]
then
    # echo "\"${IMAGE}\": image file not found."
    wrap_orientation OK not_found 99999 ""
    exit
fi
FILE_TYPE=`exiftool ${IMAGE} | grep MIME`

if [[ ! "${FILE_TYPE}" =~ image ]]
then
    # echo "\"${IMAGE}\": file type \"\" is not an image."
    wrap_orientation OK not_image 99999 ""
    exit
fi

WIDTH=200
RUN_DIR=$(dirname $0)

convert "${IMAGE}" -crop 4000x${WIDTH}+0+0 "${IMAGE}.top.jpg"
WINNER="99999"
WINNING_TYPE=''
SCORES=''
TYPE=''
while IFS=$'\t' read -r TYPE STANDARD
do
  #echo compare -channel red -metric MAE ${STANDARD} "${IMAGE}.top.jpg" z.jpg
  TOP=`compare -channel red -metric MAE ${RUN_DIR}/${STANDARD} "${IMAGE}.top.jpg" temp.jpg 2>&1 | perl -ne 'chomp; s/[\. ].*// ; print $_;'`
  # echo $TYPE $STANDARD $TOP
  SCORES="${SCORES} ${TOP}"
  if [[ $TOP -le $WINNER ]]; then
    WINNER=$TOP
    WINNING_TYPE=$TYPE
  fi
done < ${RUN_DIR}/standards.csv

if [[ $WINNING_TYPE =~ compare ]] ; then
  orientation="Not detected"
else
  if [[ $WINNING_TYPE =~ top ]] ; then
    orientation="OK"
  else
    orientation="UpsideDown"
  fi
fi
wrap_orientation $orientation ${WINNING_TYPE} ${WINNER} "$SCORES"
convert "${IMAGE}.top.jpg" -quality 60 -thumbnail 20% "${IMAGE}.top.jpg"
#rm "${IMAGE}.top.jpg" "${IMAGE}.bottom.jpg"
rm -f temp.jpg
