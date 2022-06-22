#set verbose

# target server
export URL="https://pahma.cspace.berkeley.edu/cspace-services/imports"
export USER="xxxxx@pahma.cspace.berkeley.edu:xxxxx"
export CONTENT_TYPE="Content-Type: application/xml"

# password comes from .pgpass
export CONNECTSTRING="host=dba-postgres-prod-45.ist.berkeley.edu port=5307 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma"

# setup for email
export SUBJECT="Tricoder Upload Results  `date`"
export EMAIL="pahma-tricoder@lists.berkeley.edu"

export ROOT_PATH=/cspace/batch_barcode
export UPLOAD_PATH=${ROOT_PATH}/input
