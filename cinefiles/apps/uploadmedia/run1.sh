cp pdfs/$1/* .
cp pdfs/$1.step1.csv .
/var/www/cinefiles/uploadmedia/postblob.sh cinefiles /var/cspace/cinefiles/bmu/$1 uploadmedia_batch >> /var/cspace/cinefiles/bmu/batches.log 2>&1 
rm *.pdf
