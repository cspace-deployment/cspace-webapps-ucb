#!/usr/bin/env bash

cp style.html OK.html
cp style.html UpsideDown.html
cp style.html Indeterminate.html

rm -f orientation.csv

for IMAGE in *.$1
do
  #magick "${IMAGE}" -crop 4000x120+0+0 "${IMAGE}".crop.jpg
  magick "${IMAGE}" -quality 60 -thumbnail 20% "${IMAGE}.thumb.jpg" &
  orientation=`./check_orientation.sh "${IMAGE}"`
  wait
  images=${orientation/ */}
  #echo "o $orientation"
  #echo "i $images"
  echo "<div>" >> $images.html
  echo "${IMAGE}" >> $images.html
  echo "<br/>" >> $images.html
  #magick "${IMAGE}".crop.jpg -quality 60 -thumbnail 20% "${IMAGE}.thumb.crop.jpg"
  echo $orientation >> $images.html
  echo "$IMAGE $orientation" >> orientation.csv
  echo "<hr/><img width=\"120px\" src=\"${IMAGE}.top.jpg\"><hr/><img width=\"120px\" src=\"${IMAGE}.bottom.jpg\"><hr/><img width=\"120px\" src=\"${IMAGE}.thumb.jpg\"></div>" >> $images.html
done

cut -f2 -d" " orientation.csv| sort | uniq -c > orientation.txt

