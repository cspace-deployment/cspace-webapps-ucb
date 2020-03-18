### Generating and ingesting the 59,000 CineFiles PDFs

See also https://jira.ets.berkeley.edu/jira/browse/CSW-270

There are a few steps in this process:

* Generate (i.e. "crawl") all the PDFs for existing documents (crawl-pdfs.sh)
* Create a set of BMU jobs (60 jobs of 1,000 PDFs each) to upload them (make-step1.py)
* Upload all the PDFs (run1.sh, runall.sh)

Run `crawl-pdfs.sh` to generate the PDFs (took 5h28m on Dev):

```
(venv) app_webapps@blacklight-dev:/var/cspace/cinefiles/bmu$  nohup time ./crawl-pdfs.sh docs.csv &

996.14user 409.64system 5:28:34elapsed 7%CPU (0avgtext+0avgdata 12920maxresident)k
1616inputs+131962336outputs (25major+52496868minor)pagefaults 0swaps

(venv) app_webapps@blacklight-dev:/var/cspace/cinefiles/bmu$ tail -3 nohup.out 

59303 
59303
59304 
```
There are about 62GB of PDFs
```
(venv) app_webapps@blacklight-dev:/var/cspace/cinefiles/bmu$ du -sh pdfs/
62G	pdfs/
```
Create the 60 BMU jobs, run the first one by hand to check...
```
cd /var/cspace/cinefiles/bmu/
nohup time ./run1.sh 1 &
```
Here's the script to run the rest of them:
```
(venv) app_webapps@blacklight-dev:/var/cspace/cinefiles/bmu$ cat runall.sh 
for f in {7..59}; do echo $f ; time ./run1.sh $f ; done
```
Here we run the rest of them...also takes some hours...
```
nohup time bash ./runall.sh &
```
