#!/usr/bin/env bash

IMAGE="$1"

magick "${IMAGE}" -crop 4000x200+0+0 "${IMAGE}.top.jpg"
magick "${IMAGE}" -gravity South -crop 4000x200+0+0 -rotate +180 "${IMAGE}.bottom.jpg"
top=`magick compare -channel red -metric MAE colorbar.jpg "${IMAGE}.top.jpg" z.jpg 2>&1 | perl -ne 'chomp; s/[\. ].*// ; print $_;'`
bot=`magick compare -channel red -metric MAE colorbar.jpg "${IMAGE}.bottom.jpg" z.jpg 2>&1 | perl -ne 'chomp; s/[\. ].*// ; print $_;'`
if [[ $bot -gt $top ]] ; then
  orientation="OK"
else
  orientation="UpsideDown"
fi
echo "$orientation $top $bot"
