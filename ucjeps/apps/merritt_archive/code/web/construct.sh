#!/bin/bash

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

cd archive
echo "<ul>"
for d in *
  do
    ls $d/*.jpg | echo "<li><a href=\"archive/$d\">$d</a> [`wc -l`]"
  done | sort -r
echo "</ul>"
cat << H2
</div>
<div style="width: 400px">
<h3>BMU Images</h3>
H2

cd ../bmu
echo "<ul>"
for d in *
  do
    ls $d/*.jpg | echo "<li><a href=\"bmu/$d\">$d</a> [`wc -l`]"
  done | sort -r
echo "</ul>"
# <iframe src="bmu/index.html" width="250px" height="100%" style="border:none;">

cat << H3
</div>
</div>
</html>
H3
