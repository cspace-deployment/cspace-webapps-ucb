## CSV Import

A tool to import delimited files (commas, tabs) into CSpace


How to deploy

1. Set up the webapp the usual way (i.e. follow the instructions for
deploying Django webapps)
1. Make the following directories to hold the various import files:

```
cd
mkdir -p csvimport/ucjeps
mkdir -p csvimport/pahma
chcon -R -t httpd_sys_content_t csvimport/
```

3. The "static vocabularies" need to be made available. This is done by
fetching the JSON configuration file using the CSpace UI and placing it
in the config directory:

Download the UI configuration from https://ucjeps.cspace.berkeley.edu/config.
(Click the 'Save configuration as JSON" link to download.)

Then you'll have to get it up to the server somehow, e.g.:

```
scp cspace-ui-config.json webapps.cspace.berkeley.edu:/tmp/csvimport.cspace-ui-config.json
```

Note the filename; it is hardcoded in the csvImport program right now!

```
cp /tmp/csvimport.cspace-ui-config.json ~/ucjeps/config
```

You can test / inspect this file using the `extractOptions.py` script in this directory.
It does a 'prettyprint' listing of the contents; you can save that as a file to
inspect or grep for values in it.

E.g.

```
csvimport $ python extractOptions.py ../../config/cspace-ui-config-ucjeps.json | grep 'Tropicos'
   b'Tropicos'               b'Tropicos'
```

#### The command line interface (CLI)

You can also run csvImport from the command line, without using the
webapp. There's not a good motivation for doing that that I can think of
but for long jobs or many batches of files it might be useful. And certainly for development!

Here's how to set up and run the code. Note that if csvImport is already installed
you may consider simply running it where it is installed.

Otherwise:


1. Clone the two repos you'll need.

```
git clone git@github.com:cspace-deployment/cspace-webapps-ucb.git
git clone git@github.com:cspace-deployment/cspace-webapps-common.git
```

2. Install the Django webapps the usual way. See the instructions in cspace-webapps-common


3. Several configuration files are needed. (see above)
You'll need two config file for each record type you wish to support,
a 'field definitions file' and an XML template. So, for importing
collectionobjects and taxon authority records, you'd need something like
the following:

```
config/csvimport.cfg
config/csvimport.collectionobjects.definitions.csv
config/csvimport.collectionobjects.template.xml
config/csvimport.cspace-ui-config.json
config/csvimport.extra-lists.json
config/csvimport.taxon.definitions.csv
config/csvimport.taxon.template.xml
```

NB: make sure the hostname in `csvimport` is the one you intend! Dev or Prod!
    And that the credentials are valid!

```
vi ../config/csvimport.cfg
```

4. Count, Validate, Add, Update...

You'll need to point to your input file. You can try one of the test files provided:

Count:

```
nohup time python DWC2CSpace.py test_1_commas_unicode.csv ../config/csvimport.cfg ../config/DWC2CSpace-v2.csv ../config/collectionobject-v2.xml test_1_commas_unicode.results.csv /dev/null count >test_1_commas_unicode.counts.log

```


Validate:

```
nohup time python DWC2CSpace.py test_1_commas_unicode.csv ../config/csvimport.cfg ../config/DWC2CSpace-v2.csv ../config/collectionobject-v2.xml test_1_commas_unicode.results.csv test_1_commas_unicode.terms.csv validate

```

Add:

```
nohup time python DWC2CSpace.py test_1_commas_unicode.results.csv ../config/csvimport.cfg ../config/DWC2CSpace-v2.csv ../config/collectionobject-v2.xml test_1_commas_unicode.upload.csv /dev/null add

```

Erase what you just uploaded:

```
nohup ./reset.sh test_1_commas_unicode.upload.csv > test_1_commas_unicode.delete.log
```