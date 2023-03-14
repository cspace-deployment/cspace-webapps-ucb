#!/usr/bin/env bash

sqlite3 merritt_archive.sqlite3  << HERE
DROP TABLE IF EXISTS merritt_archive_transaction ;
CREATE TABLE IF NOT EXISTS "merritt_archive_transaction" ("accession_number" text NOT NULL, "image_filename" text NOT NULL, "status" varchar(100) NOT NULL, "job" text NOT NULL, "transaction_date" datetime NOT NULL, "transaction_detail" text);

CREATE INDEX mat_accession_number on merritt_archive_transaction(accession_number);
CREATE INDEX mat_image_filename on merritt_archive_transaction(image_filename);
CREATE INDEX mat_status on merritt_archive_transaction(status);
CREATE INDEX mat_job on merritt_archive_transaction(job);

HERE
echo 'merritt_archive_transaction table created'
