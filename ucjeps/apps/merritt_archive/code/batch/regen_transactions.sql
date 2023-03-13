drop table if exists merritt_archive_transaction ;

CREATE TABLE IF NOT EXISTS "merritt_archive_transaction" ("accession_number" text NOT NULL, "image_filename" text NOT NULL, "status" varchar(100) NOT NULL, "job" text NOT NULL, "transaction_date" datetime NOT NULL, "transaction_detail" text NOT NULL);

.mode tabs
.import archived.csv merritt_archive_transaction
.import merritt_archive.csv merritt_archive_transaction
.import metadata.csv merritt_archive_transaction

select status,count(*) from merritt_archive_transaction group by status;

select * from merritt_archive_transaction where accession_number = 'JEPS58820';
select * from merritt_archive_transaction where accession_number = 'UC1058162';
select * from merritt_archive_transaction where accession_number = 'UC995170';

