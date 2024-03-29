__author__ = 'jblowe'

import re
import requests
import urllib
import time
import html

from django.contrib.auth.decorators import login_required
from django.shortcuts import render
from django.http import HttpResponse
from taxoneditor.taxon import taxon_template

from taxoneditor.utils import termTypeDropdowns, termStatusDropdowns, taxonRankDropdowns, taxonfields, labels, formfields, numberWanted
from taxoneditor.utils import extractTag, xName, TITLE, taxon_authority_csid, tropicos_api_key
from taxoneditor.utils import fromstring, lookupMajorGroup, taxontermsources

# alas, there are many ways the XML parsing functionality might be installed.
# the following code attempts to find and import the best...

from common import cspace
from common.utils import loginfo
from cspace_django_site.main import cspace_django_site

# read common config file
from common.appconfig import loadConfiguration
prmz = loadConfiguration('common')
loginfo('taxoneditor', 'Configuration for common successfully read', {}, {})

# TODO: simplify this code: parms should be read and URLs created in a single place
config = cspace_django_site.getConfig()
tenant = config.get('cspace_services_connect', 'tenant')
hostname = config.get('cspace_services_connect', 'hostname')
port = config.get('cspace_services_connect', 'port')
protocol = config.get('cspace_services_connect', 'protocol')
cspaceserver = protocol + "://" + hostname
try:
    int(port)
    cspaceserver= cspaceserver + ':' + port
except:
    pass

@login_required()
def taxoneditor(request):

    formfield = 'determinations'
    sources = []
    determinations = ''
    multipleresults = []
    sources = ['COL','CSpace', 'GBIF', 'Tropicos']
    checked_sources = sources

    if request.method == 'POST':
        determinations = request.POST[formfield]
        taxa = determinations.split('\n')
        if 'source' in request.POST:
            checked_sources = request.POST.getlist('source')
        # do search
        itemcount = 0
        sequence_number = 0
        elapsedTimes = {'COL': 0.0, 'CollectionSpace': 0.0, 'GBIF': 0.0, 'Tropicos': 0.0}
        for taxon in taxa:
            itemcount += 1
            # remove leading and trailing white space
            taxon = taxon.strip()
            taxon_prefix = taxon.replace('. ', '.')
            taxon_prefix = re.sub(r' +\(.*','',taxon_prefix)
            # extract just latin name (= "Genus species"
            taxon_prefix = re.sub(r'([A-Z][a-z\-]+) ([a-z\-]+).*',r'\1 \2', taxon_prefix)
            if taxon == '': continue
            results = {'COL': [], 'CollectionSpace': [], 'GBIF': [], 'Tropicos': []}
            # '() NameId Family ScientificNameWithAuthors ScientificName () NameId'
            if 'CSpace' in checked_sources:
                cspaceTime = time.time()
                connection = cspace.connection.create_connection(config, request.user)
                requestURL = 'cspace-services/taxonomyauthority/%s/items?pt=%s&wf_deleted=false&pgSz=%s' % (taxon_authority_csid, urllib.parse.quote_plus(taxon_prefix), numberWanted)
                (url, data, statusCode, elapsedTime) = connection.make_get_request(requestURL)
                if statusCode != 200 or data is None:
                    data = '<error>error %s</error>' % statusCode
                cspaceXML = fromstring(data)
                items = cspaceXML.findall('.//list-item')
                numberofitems = len(items)
                if numberofitems > numberWanted:
                    items = items[:numberWanted]
                for i in items:
                    sequence_number += 1
                    csid = i.find('.//csid')
                    csid = csid.text
                    termDisplayName = extractTag(i,'termDisplayName')
                    taxonRefname = extractTag(i,'taxon')
                    (url, taxondata, statusCode, elapsedTime) = connection.make_get_request(
                        'cspace-services/taxonomyauthority/%s/items/%s' % (taxon_authority_csid, csid))
                    loginfo('taxoneditor', '%s cspace-services/taxonomyauthority/%s/items/%s' % (elapsedTime, taxon_authority_csid, csid), {}, {})
                    taxonXML = fromstring(taxondata)
                    family = extractTag(taxonXML, 'family')
                    major_group = extractTag(taxonXML, 'taxonMajorGroup')
                    updated_at = extractTag(taxonXML, 'updatedAt')
                    #termDisplayName = extractTag(taxonXML, 'termDisplayName')
                    termName = extractTag(taxonXML, 'termName')
                    commonName = extractTag(taxonXML, 'commonName')

                    r = [sequence_number, family, major_group, termDisplayName, termName, commonName, 'CSpace', csid, updated_at]
                    r = [ ['', x] for x in r]

                    results['CollectionSpace'].append(r)
                cspaceTime = time.time() - cspaceTime
                elapsedTimes['CollectionSpace'] += cspaceTime
                loginfo('taxoneditor', '%s %s %s items %s' % (itemcount, cspaceTime, numberofitems, url), {}, {})
            if 'Tropicos' in checked_sources:
                tropicosTime = time.time()
                # do Tropicos search
                # params = urllib.urlencode({'name': taxon})
                tropicosURL = "http://services.tropicos.org/Name/Search"
                response = requests.get(tropicosURL, params={'name': taxon_prefix.replace('.','%2E'), 'pagesize':numberWanted, 'apikey':tropicos_api_key, 'format': 'json'})
                #loginfo('taxoneditor', tropicosURL, {}, {})
                response.encoding = 'utf-8'
                try:
                    names2use = response.json()
                    if 'Error' in names2use[0]:
                        loginfo('taxoneditor', 'ERROR: from Tropicos: %s' % names2use['Error'], {}, {})
                        names2use = []
                except:
                    loginfo('taxoneditor', 'ERROR: could not parse returned Tropicos JSON, or it was empty', {}, {})
                    names2use = []
                numberofitems = len(names2use)
                if len(names2use) > numberWanted:
                    names2use = names2use[:numberWanted]
                for name in names2use:
                    sequence_number += 1
                    r = []
                    for i,fieldname in enumerate('X Family X ScientificNameWithAuthors ScientificName CommonName X NameId'.split(' ')):
                        r.append(xName(name, fieldname, i))
                    r[0] = ['id', sequence_number]
                    r[6] = ['termSource', 'Tropicos']
                    #r = {'id': sequence_number, 'family': name['Family'], 'idsource': 'Tropicos', 'id': name['NameId'],
                    #     'scientificnamewithauthors': name['ScientificNameWithAuthors'],
                    #     'scientificname': name['ScientificName']}
                    results['Tropicos'].append(r)
                tropicosTime = time.time() - tropicosTime
                elapsedTimes['Tropicos'] += tropicosTime
                loginfo('taxoneditor', '%s %s %s items http://services.tropicos.org/Name/Search name=%s' % (itemcount, tropicosTime, numberofitems, urllib.parse.quote_plus(taxon_prefix)), {}, {})
            if 'GBIF' in checked_sources:
                gbifTime = time.time()
                # do GBIF search
                # params = urllib.urlencode({'name': taxon_prefix})
                response = requests.get('http://api.gbif.org/v1/species/search', params={'q': taxon_prefix})
                response.encoding = 'utf-8'

                names2use = response.json()
                names2use = names2use['results']
                numberofitems = len(names2use)
                if len(names2use) > numberWanted:
                    names2use = names2use[:numberWanted]
                for name in names2use:
                    if 'accordingTo' in name and 'NUB Generator' in name['accordingTo']:
                        continue
                    sequence_number += 1
                    # get phylum from both?!
                    r = []
                    for i,fieldname in enumerate('X family phylum scientificName canonicalName CommonName X taxonID'.split(' ')):
                        r.append(xName(name, fieldname, i))
                    r[2][1] = lookupMajorGroup(r[2][1])
                    r[0] = ['id', sequence_number]
                    r[6] = ['termSource','GBIF']
                    results['GBIF'].append(r)
                gbifTime = time.time() - gbifTime
                elapsedTimes['GBIF'] += gbifTime
                loginfo('taxoneditor', '%s %s %s items http://api.gbif.org/v1/species/search q=%s' % (itemcount, gbifTime, numberofitems, urllib.parse.quote_plus(taxon_prefix)), {}, {})
            if 'COL' in checked_sources:
                colTime = time.time()
                # do COL search
                # https://api.catalogueoflife.org/nameusage/search?q=Orthodontium%20gracile&offset=0&limit=10
                response = requests.get('https://api.catalogueoflife.org/nameusage/search', params={'q': taxon_prefix})
                response.encoding = 'utf-8'

                names2use = response.json()
                try:
                    names2use = names2use['result']
                except:
                    names2use = []
                numberofitems = len(names2use)
                if len(names2use) > numberWanted:
                    names2use = names2use[:numberWanted]
                for name in names2use:
                    # skip names without an id -- they are 'defective' for this purpose
                    if 'id' not in name:
                        continue
                    sequence_number += 1
                    # get phylum from both?!
                    r = []
                    x = {'family': '', 'phylum': ''}
                    if 'classification' in name:
                        name_list = name['classification']
                        for n in name_list:
                            for p in x:
                                if p in n['rank'] and 'name' in n:
                                    x[p] = n['name']
                    else:
                        name_list = []
                    for i,fieldname in enumerate('X family majorgroup termDisplayName termName CommonName termSource termSourceID'.split(' ')):
                        for name_part in name_list:
                            if fieldname in name_part['rank'] and 'name' in name_part:
                                found = name_part['name']
                            else:
                                found = ''
                        r.append([fieldname, found])
                    r[1][1] = x['family']
                    r[2][1] = x['phylum']
                    r[2][1] = lookupMajorGroup(r[2][1])
                    r[3][1] = name['usage']['labelHtml']
                    r[4][1] = name['usage']['name']['scientificName']
                    r[0] = ['id', sequence_number]
                    r[6] = ['termSource','COL']
                    r[7] = ['termSourceID', name['id']]
                    results['COL'].append(r)
                colTime = time.time() - colTime
                elapsedTimes['COL'] += colTime
                loginfo('taxoneditor', '%s %s %s items https://api.catalogueoflife.org/nameusage/search q=%s' % (itemcount, colTime, numberofitems, urllib.parse.quote_plus(taxon_prefix)), {}, {})

            multipleresults.append([taxon, taxon_prefix, results, itemcount])

    timestamp = time.strftime("%b %d %Y %H:%M:%S", time.localtime())
    return render(request, 'taxoneditor.html', {'timestamp': timestamp, 'version': prmz.VERSION, 'fields': formfields,
                                                'labels': labels, 'multipleresults': multipleresults, 'taxa': determinations,
                                                'suggestsource': 'solr',
                                                'sources': sources,
                                                'checked_sources': checked_sources,
                                                'institution': tenant,
                                                'cspaceserver': cspaceserver,
                                                'csrecordtype': 'taxon',
                                                'apptitle': TITLE})


def load_payload(payload, request, cspace_fields):
    for field in cspace_fields:
        cspace_name = field[0]
        if cspace_name in request.POST.keys():
            if cspace_name == 'termSource':
                try:
                    termSourceRefName = taxontermsources[request.POST[cspace_name]]
                    payload = payload.replace('{%s}' % cspace_name, termSourceRefName)
                except:
                    payload = payload.replace('{%s}' % cspace_name, 'unrecognized')
            else:
                payload = payload.replace('{%s}' % cspace_name, html.escape(request.POST[cspace_name]))

    # get rid of any unsubstituted items in the template
    payload = re.sub(r'\{.*?\}', '', payload)
    #payload = payload.replace('INSTITUTION', institution)
    return payload


@login_required()
def create_taxon(request):

    payload = load_payload(taxon_template,request,taxonfields)
    uri = 'cspace-services/%s/%s/items' % ('taxonomyauthority', taxon_authority_csid)

    messages = {'cspaceserver': cspaceserver}
    # messages.append("posting to %s REST API..." % uri)
    # loginfo('taxoneditor', payload, {}, {})
    # messages.append(payload)

    connection = cspace.connection.create_connection(config, request.user)
    taxonCSID = ''
    try:
        (url, data, taxonCSID, elapsedtime) = connection.postxml(uri=uri, payload=payload, requesttype='POST')
        if data is None:
            messages['error'] = "got HTTP response %s for POST to %s; don't think it worked. " % (taxonCSID, uri)
        messages['item'] = request.POST['item']
        messages['csid'] = taxonCSID
    except:
        messages['error'] = "got HTTP response %s for POST to %s; don't think it worked. " % (taxonCSID, uri)
        elapsedtime = 0.0

    messages['elapsedtime'] = elapsedtime
    return render(request, 'taxon_save_result.html', messages)
