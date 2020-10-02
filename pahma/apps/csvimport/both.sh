#!/bin/bash
cd $( dirname "${BASH_SOURCE[0]}" )
PYTHON=/var/www/venv/bin/python
set -x
touch $1.inprogress.log
rm -f $1.runlog.out
time $PYTHON DWC2CSpace.py $1.both.csv ../config/csvimport.cfg ../config/csvimport.$2.definitions.csv ../config/csvimport.$2.template.xml $1.both-audit.csv /dev/null /dev/null both $2 > $1.runlog.out 2>&1
grep -v Insec $1.runlog.out > $1.updated.log; rm $1.runlog.out
cat $1.inprogress.log >> $1.runstatistics.log ; rm $1.inprogress.log