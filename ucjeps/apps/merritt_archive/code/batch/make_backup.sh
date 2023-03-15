#!/usr/bin/env bash

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

export RUN_DATE=`date +%Y-%m-%d-%H-%M`
# make a backup
cp ${SQLITE3_DB} ${SQLITE3_DB}.backup.${RUN_DATE}

