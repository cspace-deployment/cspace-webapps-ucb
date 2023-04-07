#!/usr/bin/env bash

IMAGE="$1"
WIDTH=250

convert "${IMAGE}" -crop 4000x${WIDTH}+0+0 "${IMAGE}.top.jpg"
convert "${IMAGE}" -gravity South -crop 4000x${WIDTH}+0+0 -rotate +180 "${IMAGE}.bottom.jpg"
top=`compare -channel red -metric MAE colorbar.top.jpg "${IMAGE}.top.jpg" temp.jpg 2>&1 | perl -ne 'chomp; s/[\. ].*// ; print $_;'`
bot=`compare -channel red -metric MAE colorbar.bottom.jpg "${IMAGE}.bottom.jpg" temp.jpg 2>&1 | perl -ne 'chomp; s/[\. ].*// ; print $_;'`
if [[ $bot -gt $top ]] ; then
  orientation="OK"
else
  orientation="UpsideDown"
fi
echo "$orientation $top $bot"
rm -f "${IMAGE}.top.jpg" "${IMAGE}.bottom.jpg" temp.jpg