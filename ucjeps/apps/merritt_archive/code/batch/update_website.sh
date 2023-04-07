#!/usr/bin/env bash

# update transaction database with latest data regarding archived images

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

cat << H1
<html>
<head>
<style>
div { float: left; }
</style>
</head>
<div style="width: 100%">
<div id="archive" style="width: 400px">
<h3>Archive Images</h3>
H1

aws s3 ls --recursive s3://ucjeps-archiving-thumbnails/qa/thumbs/archive > temp1
perl -pe 's#.*archive/##;s#/.*##' temp1 | sort -r | uniq -c > temp2
echo "<ul>"
while read -r COUNT JOB
  do
    echo "<li><a href=\"archive/${JOB}\">${JOB}</a> [${COUNT}]"
  done < temp2
echo "</ul>"

cat << H2
</div>
<div style="width: 400px">
<h3>BMU Images</h3>
H2

aws s3 ls --recursive s3://ucjeps-archiving-thumbnails/qa/thumbs/bmu > temp1
perl -pe 's#.*archive/##;s#/.*##' temp1 | sort -r | uniq -c > temp2
echo "<ul>"
while read -r COUNT JOB
  do
    echo "<li><a href=\"bmu/${JOB}\">${JOB}</a> [${COUNT}]"
  done < temp2
echo "</ul>"
# <iframe src="bmu/index.html" width="250px" height="100%" style="border:none;">

cat << H3
</div>
</div>
</html>
H3
