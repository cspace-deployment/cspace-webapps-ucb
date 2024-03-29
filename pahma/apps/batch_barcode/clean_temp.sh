#!/bin/bash

# this script cleans up after a tricoder upload run
find temp/location -type f  -delete
find temp/relation -type f  -delete
find temp/location/done -type f  -delete
find temp/location/done_id -type f  -delete
find temp/relation/done -type f  -delete

find /tmp/all_*  -type f -delete > /dev/null 2>&1

cd /tmp ; ls /tmp | perl -ne "print if /^\d+$/" | xargs rm
