
import sys
import codecs

import time
import urllib2
import re
import psycopg2

sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

timeoutcommand = "set statement_timeout to 240000; SET NAMES 'utf8';"


def getCSID(argType, arg, config):
    dbconn = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)

    if argType == 'objectnumber':
        query = """SELECT h.name from collectionobjects_common cc
JOIN hierarchy h on h.id=cc.id
JOIN misc on (cc.id = misc.id and misc.lifecyclestate <> 'deleted')
WHERE objectnumber = '%s'""" % arg
    elif argType == 'placeName':
        query = """SELECT h.name from places_common pc
JOIN hierarchy h on h.id=pc.id
JOIN misc on (pc.id = misc.id and misc.lifecyclestate <> 'deleted')
WHERE pc.refname ILIKE '%""" + arg + "%%'"

    objects.execute(query)
    return objects.fetchone()


MAXLOCATIONS = 1000


def postxml(requestType, uri, realm, server, username, password, payload):
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    url = "%s/cspace-services/%s" % (server, uri)
    elapsedtime = 0.0

    elapsedtime = time.time()
    request = urllib2.Request(url, payload.encode('utf-8'), {'Content-Type': 'application/xml'})
    # default method for urllib2 with payload is POST
    if requestType == 'PUT': request.get_method = lambda: 'PUT'
    try:
        f = urllib2.urlopen(request)
    except urllib2.URLError as e:
        if hasattr(e, 'reason'):
            sys.stderr.write('We failed to reach a server.\n')
            sys.stderr.write('Reason: ' + str(e.reason) + '\n')
        if hasattr(e, 'code'):
            sys.stderr.write('The server couldn\'t fulfill the request.\n')
            sys.stderr.write('Error code: ' + str(e.code) + '\n')
        if True:
            sys.stderr.write("Error in POSTing!\n")
            sys.stderr.write("%s\n" % url)
            sys.stderr.write(payload)
            raise

    data = f.read()
    info = f.info()
    # if a POST, the Location element contains the new CSID
    if info['Location']:
        csid = re.search(uri + '/(.*)', info['Location'])
        csid = csid.group(1)
    else:
        csid = ''
    elapsedtime = time.time() - elapsedtime
    return (url, data, csid, elapsedtime)


def relationsPayload(f):
    payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="relations">
  <ns2:relations_common xmlns:ns2="http://collectionspace.org/services/relation" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <relationshipType>affects</relationshipType>
    <objectCsid>%s</objectCsid>
    <objectDocumentType>%s</objectDocumentType>
    <subjectCsid>%s</subjectCsid>
    <subjectDocumentType>%s</subjectDocumentType>
  </ns2:relations_common>
</document>
"""
    payload = payload % (f['objectCsid'], f['objectDocumentType'], f['subjectCsid'], f['subjectDocumentType'])
    return payload

