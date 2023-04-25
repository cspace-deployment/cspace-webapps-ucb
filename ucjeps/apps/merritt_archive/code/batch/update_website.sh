#!/usr/bin/env bash

# update transaction database with latest data regarding archived images

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

cat << H1
<html>
<head>
<style>
div { float: left; }
</style>
<link rel="stylesheet" href="/specimen.css" type="text/css">
</head>
<div style="width: 100%">
<div id="archive" style="width: 400px">
<h3>Archive Images</h3>
H1

aws s3 ls --recursive ${WEBSITE_BUCKET}/archive | grep .jpg > temp1
perl -pe 's#.*archive/##;s#/.*##' temp1 | sort -r | uniq -c > temp2
echo "<ul>"
while read -r COUNT JOB
  do
    echo "<li><a href=\"archive/${JOB}/index.html\">${JOB}</a> [${COUNT}]"
  done < temp2
echo "</ul>"

cat << H2
</div>
<div style="width: 400px">
<h3>BMU Images</h3>
H2

aws s3 ls --recursive ${WEBSITE_BUCKET}/bmu | grep .jpg > temp1
perl -pe 's#.*?bmu/##;s#/.*##' temp1 | sort -r | uniq -c > temp2
echo "<ul>"
while read -r COUNT JOB
  do
    echo "<li><a href=\"bmu/${JOB}/index.html\">${JOB}</a> [${COUNT}]"
  done < temp2
echo "</ul>"

cat << H3
</div>
</div>
</html>
H3
