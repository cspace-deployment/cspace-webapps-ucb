#!/usr/bin/env bash

if [[ ! "$2" == "" ]]
then
    echo $2
fi

tmpfile=$(mktemp /tmp/ucjeps-archiving-temp.XXXXXX)

exiftool $1 > ${tmpfile}
grep "White Balance" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Color Temperature" ${tmpfile} | perl -pe 's/             //' | head -1
grep "WB Adj Color Temp" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Color Temp As Shot" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Orientation" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Image Width" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Image Height" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Camera Model Name" ${tmpfile} | perl -pe 's/             //' | head -1

rm "$tmpfile"
