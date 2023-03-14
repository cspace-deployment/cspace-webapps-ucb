#!/usr/bin/env bash

sqlite3 merritt_archive.sqlite3  << HERE

select status,count(*) from merritt_archive_transaction group by status;

select * from merritt_archive_transaction where accession_number = 'JEPS58820';
select * from merritt_archive_transaction where accession_number = 'UC1058162';
select * from merritt_archive_transaction where accession_number = 'UC995170';

HERE

