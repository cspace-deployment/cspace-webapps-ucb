# credentials, etc. required to make the ucjeps merritt archiving pipeline work

# used to retrieve signed urls for the images in merritt's s3 bucket
export MERRITT_USER="<getfrommerritt>"
export MERRITT_PASSWORD="<getfrommerritt>"
export MERRIT_BUCKET=jepson-snowcone.uc3dev.cdlib.org

# used to submit "batches" of "jobs" to merritt ingest
export COLLECTION_USERNAME="<getfrommerritt>"
export COLLECTION_PASSWORD="<getfrommerritt>"

# our s3 bucket for transitory images
export S3BUCKET="https://cspace-merritt-in-transit-qa.s3.us-west-2.amazonaws.com"
export SUBMITTER="jblowe"

# location of job files used by archiving pipeline
export JOB_DIRECTORY="/cspace/merritt/jobs"

# database of pipeline transactions
export SQLITE3_DB="mxrritt_archive.sqlite3"