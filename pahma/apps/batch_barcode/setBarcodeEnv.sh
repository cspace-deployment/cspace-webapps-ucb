#set verbose

# target server
export URL="https://pahma-dev.cspace.berkeley.edu/cspace-services/imports"
export USER="xxx@pahma.cspace.berkeley.edu:xxxx"
export CONTENT_TYPE="Content-Type: application/xml"

# password comes from .pgpass
export CONNECTSTRING="host=dba-postgres-dev-45.ist.berkeley.edu port=5117 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma "

# setup for email
export SUBJECT="Tricoder Upload Results  `date`"
#export EMAIL="pahma-tricoder@lists.berkeley.edu"
#export EMAIL="mtblack@berkeley.edu"
export EMAIL="jblowe@berkeley.edu"

export ROOT_PATH=/cspace/batch_barcode
export UPLOAD_PATH=${ROOT_PATH}/input
