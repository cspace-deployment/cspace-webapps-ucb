#!/bin/bash
cd $( dirname "${BASH_SOURCE[0]}" )
PYTHON=/var/www/venv/bin/python
set -x
touch $1.inprogress.log
rm -f $1.runlog.out
time $PYTHON DWC2CSpace.py $1.input.csv ../config/csvimport.cfg ../config/csvimport.$2.definitions.csv ../config/csvimport.$2.template.xml $1.valid.csv $1.invalid.csv $1.terms.csv validate-add $2 > $1.runlog.out 2>&1
mv $1.valid.csv $1.add.csv
grep -v Insec $1.runlog.out > $1.validated.log; rm $1.runlog.out
cat $1.inprogress.log >> $1.runstatistics.log ; rm $1.inprogress.log
