#!/bin/bash
#

# there are almost 60,000 documents
# let's bin them in directories of 1,000
# mkdir /var/cspace/cinefiles/bmu/pdfs
# for i in {1..60}; do mkdir /var/cspace/cinefiles/bmu/pdfs/$i ; done
# ls pdfs/
# 1  10  2  3  4  5  6  7  8  9 ... 60

if [ $# -ne 1 ]; then
    echo Usage: $0 listofdocids.csv
    exit
fi

if [ -r $1 ];
then
  for item in  `cut -f1 $1`
  do
    dir=$(( 1 + (item / 1000) ))
    curl -s -S "https://cinefiles.bampfa.berkeley.edu/cinefiles/DocPdf?docId=${item}&pgs=all" -o /var/cspace/cinefiles/bmu/pdfs/${dir}/${item}.pdf
    #sleep 1
    echo ${item}
  done
else
  echo "$1 -- list of docids not found."
fi
