#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }
sqlite3 ${SQLITE3_DB}  << HERE

select status,count(*) from merritt_archive_transaction group by status;

select * from merritt_archive_transaction where accession_number = 'JEPS58820';
select * from merritt_archive_transaction where accession_number = 'UC1058162';
select * from merritt_archive_transaction where accession_number = 'UC995170';
select * from merritt_archive_transaction where accession_number = 'UC119079';
select * from merritt_archive_transaction where accession_number = 'UC1152579';
select * from merritt_archive_transaction where accession_number = 'UC1177704';

HERE

