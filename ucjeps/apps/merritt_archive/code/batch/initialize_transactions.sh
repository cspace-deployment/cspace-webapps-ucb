#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }
SQLITE3_DB="${SQLITE3_DB}"

read -r -p "This will erase all transactions, OK? [y/N] " response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo
    echo "Quitting, leaving transactions table in ${SQLITE3_DB} alone!"
    exit 1
fi

sqlite3 ${SQLITE3_DB}  << HERE
DROP TABLE IF EXISTS merritt_archive_transaction ;

CREATE TABLE IF NOT EXISTS "merritt_archive_transaction" (
  "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  "accession_number" text NOT NULL,
  "image_filename" text NOT NULL,
  "status" text NOT NULL,
  "job" text NOT NULL,
  "transaction_date" datetime NOT NULL,
  "transaction_detail" text
 );

CREATE INDEX mat_accession_number on merritt_archive_transaction(accession_number);
CREATE INDEX mat_image_filename on merritt_archive_transaction(image_filename);
CREATE INDEX mat_status on merritt_archive_transaction(status);
CREATE INDEX mat_job on merritt_archive_transaction(job);

HERE
echo 'merritt_archive_transaction table (re)created'
