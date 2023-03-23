#!/usr/bin/env bash
#
# make UCJEPS skeletal records

CREDENTIALS="$1"
SERVER="$2"
ACCESSIONS="$3"
TEMPLATE="collectionobjects.xml"

SERVICE="cspace-services/collectionobjects"
CONTENT_TYPE="Content-Type: application/xml"


if [ $# -ne 3 ]; then
    echo "Usage: $0 <credentials> <server> <file_of_accession_numbers>"
    echo
    exit 1
fi

if [ "$CREDENTIALS" == "" ] || [ "$SERVER" == "" ] || [ "$ACCESSIONS" == "" ]; then
    echo "credentials and/or server and/or list of accessions not provided"
    exit 1
fi

if [ ! -e "$ACCESSIONS" ]; then
    echo "file $ACCESSIONS does not exist"
    exit 1
fi

for ACCESSION in `cut -f1 ${ACCESSIONS}`
do
  echo "accession: ${ACCESSION}"
  perl -pe 's/#objectnumber#/'"${ACCESSION}"'/g' collectionobject.xml  > tempreportpayload.xml
  echo curl -s -S -L -X POST $SERVER/$SERVICE -i -u "$CREDENTIALS" -H "$CONTENT_TYPE" -T tempreportpayload.xml
  curl -s -S -L -X POST $SERVER/$SERVICE -i -u "$CREDENTIALS" -H "$CONTENT_TYPE" -T tempreportpayload.xml
done

