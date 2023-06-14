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

TEMP1=$(mktemp /tmp/ucjeps-archiving-temp.XXXXXX)
TEMP2=$(mktemp /tmp/ucjeps-archiving-temp.XXXXXX)
aws s3 ls --recursive ${WEBSITE_BUCKET}/arc | grep .jpg > $TEMP1
grep -v 'original' $TEMP1 | perl -pe 's#.*arc/##;s#/.*##' | sort -r | uniq -c > $TEMP2
echo "<ul>"
while read -r COUNT JOB
  do
    echo "<li><a href=\"arc/${JOB}/index.html\">${JOB}</a> [${COUNT}]"
  done < $TEMP2
echo "</ul>"

cat << H2
</div>
<div style="width: 400px">
<h3>BMU Images</h3>
H2

aws s3 ls --recursive ${WEBSITE_BUCKET}/bmu | grep .jpg > $TEMP1
perl -pe 's#.*?bmu/##;s#/.*##' $TEMP2 | sort -r | uniq -c > $TEMP2
echo "<ul>"
while read -r COUNT JOB
  do
    echo "<li><a href=\"bmu/${JOB}/index.html\">${JOB}</a> [${COUNT}]"
  done < $TEMP2
echo "</ul>"

cat << H3
</div>
</div>
</html>
H3
rm $TEMP1 $TEMP2
