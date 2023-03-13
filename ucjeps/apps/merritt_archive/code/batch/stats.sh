#!/bin/bash

if [[ ! "$2" == "" ]]
then
    echo $2
fi
exiftool $1 | grep Orient | perl -pe 's/             //' | head -1
exiftool $1 | grep "Camera Orient" | perl -pe 's/             //' | head -1
exiftool $1 | grep "Image Width" | perl -pe 's/             //' | head -1
exiftool $1 | grep "Image Height" | perl -pe 's/             //' | head -1
exiftool $1 | grep "Camera Model Name" | perl -pe 's/             //' | head -1 

