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
<h2>job: $2</h2>
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
</body>
</html>
HERE2
