#!/usr/bin/env bash

export RUN_DATE=`date +%Y-%m-%d-%H-%M`
# make a backup
cp merritt_archive.sqlite3 merritt_archive.backup.${RUN_DATE}

