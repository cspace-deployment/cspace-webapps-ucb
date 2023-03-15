#!/usr/bin/env bash

IN="$1"

cd /var/www/static/thumbs/bmu/${IN} || { echo "Error could not find /var/www/static/bmu/thumbs/${IN}"; exit 1; }

OUT="index.html"

echo "<html><head><link rel=\"stylesheet\" href=\"/thumbs/specimen.css\" type=\"text/css\"></head>" > ${OUT}
echo "<h3>job ${IN}, `ls *.jpg | wc -l` images</h3>" >> ${OUT}

for IMG in *.jpg
  do
    ((COUNTER++))

    echo "<div class=\"specimen\">" >> ${OUT}
    echo "<a target=\"_blank\" href=\"$IMG\"><img width=\"200px\" src=\"${IMG}\"></a>" >> ${OUT}
    echo "<pre>" >> ${OUT}
    echo "</pre>" >> ${OUT}
    echo "</div>" >> ${OUT}
  done
echo "</html>" >> ${OUT}
