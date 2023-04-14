#!/usr/bin/env bash

IMAGE="$1"
WIDTH=200

convert "${IMAGE}" -crop 4000x${WIDTH}+0+0 "${IMAGE}.top.jpg"
WINNER="99999"
WINNING_TYPE=''
SCORES=''
while IFS=$'\t' read -r TYPE STANDARD
do
  #echo compare -channel red -metric MAE ${STANDARD} "${IMAGE}.top.jpg" z.jpg
  TOP=`compare -channel red -metric MAE ${STANDARD} "${IMAGE}.top.jpg" z.jpg 2>&1 | perl -ne 'chomp; s/[\. ].*// ; print $_;'`
  # echo $TYPE $STANDARD $TOP
  SCORES="${SCORES} ${TOP}"
  if [[ $TOP -le $WINNER ]]; then
    WINNER=$TOP
    WINNING_TYPE=$TYPE
  fi
done < standards.csv
#wait
if [[ $WINNING_TYPE =~ top ]] ; then
  orientation="OK"
else
  orientation="UpsideDown"
fi
echo "$orientation ${WINNING_TYPE} ${WINNER} : $SCORES"
convert "${IMAGE}.top.jpg" -quality 60 -thumbnail 20% "${IMAGE}.top.jpg"
#rm "${IMAGE}.top.jpg" "${IMAGE}.bottom.jpg"
