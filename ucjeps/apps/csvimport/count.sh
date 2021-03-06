#!/bin/bash
cd $( dirname "${BASH_SOURCE[0]}" )
PYTHON=/var/www/venv/bin/python
set -x
rm -f $1.runlog.out
touch $1.inprogress.log
time $PYTHON DWC2CSpace.py $1.input.csv ../config/csvimport.cfg ../config/csvimport.$2.definitions.csv ../config/csvimport.$2.template.xml $1.count.csv /dev/null /dev/null count $2 > $1.runlog.out 2>&1
grep -v Insec $1.runlog.out > $1.counted.log; rm $1.runlog.out
cat $1.inprogress.log >> $1.runstatistics.log ; rm $1.inprogress.log

