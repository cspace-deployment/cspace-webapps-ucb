#!/usr/bin/env bash

# create an 'index.html' to allow easy browsing of pages of archival thumbnails

source step1_set_env.sh || { echo 'could not set environment vars. is step1_set_env.sh available?'; exit 1; }

cd "$1" || exit 1

cat << HERE1
<html>
<head>
    <script src="https://code.jquery.com/jquery.min.js"></script>
    <script>
        \$(function () {
            \$(".link").on("click", function (e) {
                var page = this.href;
                \$("#content").load(page);
                return false;
            });
        });
    </script>
    <link rel="stylesheet" href="/specimen.css" type="text/css">
</head>
<body>
<div class="row">
  <div id="job">
    <h3>job: $2</h3>
  </div>
  <div id="back">
    <h5><a href="../../index.html">back</a></h5>
  </div>
</div>
<div class="row">
  <div id="nav">
    <ul>
HERE1

for page in page*.html
  do
    echo "      <li><a class="link" href="$page">${page/.html/}</a></li>"
  done

cat << HERE2
    </ul>
  </div>
  <div id="content">Click links at left to load a page of images</div>
</div>
</body>
</html>
HERE2
