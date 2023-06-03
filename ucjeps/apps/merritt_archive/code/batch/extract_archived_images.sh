#!/usr/bin/env bash
#

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

echo "extracting archived image data from sqlite3 database..."
sqlite3 ${SQLITE3_DB}  << HERE
.mode tabs
select * from merritt_archive_transaction where status = 'archived';
HERE
