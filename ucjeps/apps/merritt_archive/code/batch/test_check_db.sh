#!/usr/bin/env bash

# test the check_db.sh script, which fetches stuff from the db based on acc.nos. and filenames

set -v
./check_db.sh JEPS100000.TIF archivable
./check_db.sh JEPS100000.TIF archived
./check_db.sh JEPS100000.TIF blocked
./check_db.sh JEPS100000.TIF media
./check_db.sh JEPS100000.TIF metadata
./check_db.sh JEPS100000.TIF snowcone

./check_db.sh JEPS100000 archivable
./check_db.sh JEPS100000 archived
./check_db.sh JEPS100000 blocked
./check_db.sh JEPS100000 media
./check_db.sh JEPS100000 metadata
./check_db.sh JEPS100000 snowcone

./check_db.sh UC1020799_2.TIF blocked
./check_db.sh UC1020799_2.TIF media
./check_db.sh UC1020799_2.TIF metadata
./check_db.sh UC1020799_2.TIF snowcone
./check_db.sh UC6911544 archived
./check_db.sh UC6911544 blocked
./check_db.sh UC6911544 metadata
./check_db.sh UC987150 metadata

./check_db.sh JEPS100000.TIF blxcked
./check_db.sh JEPS10000x.TIF media
