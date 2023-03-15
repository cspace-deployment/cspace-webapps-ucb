#!/bin/bash

if [[ ! "$2" == "" ]]
then
    echo $2
fi

tmpfile=$(mktemp /tmp/ucjeps-archiving.XXXXXX)

exiftool $1 > ${tmpfile}
grep Orient ${tmpfile} | perl -pe 's/             //' | head -1
grep "Camera Orient" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Image Width" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Image Height" ${tmpfile} | perl -pe 's/             //' | head -1
grep "Camera Model Name" ${tmpfile} | perl -pe 's/             //' | head -1

rm "$tmpfile"
