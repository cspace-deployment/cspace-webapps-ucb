import time
import logging
from cspace_django_site.main import cspace_django_site
from common import cspace
import solr
from common.utils import loginfo

from xml.etree.ElementTree import fromstring

# global variables (at least to this module...)
config = cspace_django_site.getConfig()

loginfo('location history startup', '', {}, {})


def getfromCSpace(uri, request):
    connection = cspace.connection.create_connection(config, request.user)
    url = "cspace-services/" + uri
    return connection.make_get_request(url)


def find_items_in_cspace(request, thing, keyword, pgSz):

    # TIMESTAMP = time.strftime("%b %d %Y %H:%M:%S", time.localtime())
    things = '%ss' % thing
    asquery = '%s?as=%s_common%%3Atitle%%3D%%27%s%%27&wf_deleted=false&pgSz=%s' % (things, things, keyword, pgSz)

    # Make authenticated connection to cspace server...
    (thing_url, thing_record, dummy, elapsedtime) = getfromCSpace(asquery, request)
    if thing_record is None:
        return(None, None, 0, [], "Error: the search for thing '%s' failed." % keyword)
    thing_recordtree = fromstring(thing_record)
    thing_csid = thing_recordtree.find('.//csid')
    if thing_csid is None:
        return(None, None, 0, [], None)
    thing_csid = thing_csid.text

    uri = 'collectionobjects?rtObj=%s&pgSz=%s' % (thing_csid, pgSz)
    try:
        (thing_url, thing_members, dummy, elapsedtime) = getfromCSpace(uri, request)
        thing_members = fromstring(thing_members)
        totalItems = thing_members.find('.//totalItems')
        totalItems = int(totalItems.text)
        objectcsids = [e.text for e in thing_members.findall('.//csid')]
    except:
        return (None, None, 0, [], 'Error: we could not make list of thing_members')

    return (keyword, thing_csid, totalItems, objectcsids, None)


def setup_solr_search(queryterms, context, prmz, request, searchterm):
    querystring = ' OR '.join(queryterms)
    context['searchValues']['querystring'] = querystring
    context['searchValues']['url'] = ''
    context['searchValues']['maxresults'] = prmz.MAXRESULTS
    loginfo('locationhistory', 'start location history search', context, request)
    return do_location_search(context, prmz, querystring, searchterm)


def do_location_search(context, prmz, querystring, searchterm):
    elapsedtime = time.time()
    solr_server = 'http://localhost:8983/solr'
    solr_core = 'pahma-locations'
    solrfl = 'object_csid_s id location_s crate_s locationdate_dt objectname_s objectcount_s objectnumber_s sortableobjectnumber_s'.replace(' ',',')

    # loginfo('locationhistory', 'Solr query: %s' % querystring, {}, {})
    try:
        startpage = context['maxresults'] * (context['start'] - 1)
    except:
        startpage = 0
        context['start'] = 1

    # create a connection to a solr server
    s = solr.SolrConnection(url='%s/%s' % (solr_server, solr_core))

    loginfo('locationhistory', 'query: %s' % querystring, {}, {})
    try:
        maxresults = 10000
        solrtime = time.time()
        response = s.query(querystring, facet='true', fq={}, fields=solrfl,
                           rows=maxresults, facet_limit=prmz.MAXFACETS, sort=context['sortkey'],
                           facet_mincount=1, start=startpage)
        loginfo('locationhistory', 'Solr search succeeded, %s results, %s rows requested starting at %s; %8.2f seconds.' % (response.numFound, maxresults, startpage, time.time() - solrtime), {}, {})
    # except:
    except Exception as inst:
        # raise
        loginfo('locationhistory', 'Solr search failed: %s' % str(inst), {}, {})
        context['errormsg'] = 'Solr query failed'
        return context

    results = []
    objects = {}
    locations = {}
    for i,r in enumerate(response.results):
        csid = r['object_csid_s']
        if csid in objects:
            pass
        else:
            locations[csid] = []
            objects[csid] = {'csid': csid, 'sortkey': r['sortableobjectnumber_s'], 'counter': i+1, 'otherfields': []}
            for cell in 'objectnumber_s objectname_s objectcount_s'.split(' '):
                if cell in r:
                    objects[csid]['otherfields'].append({'name' :cell, 'value': r[cell]})
                else:
                    objects[csid]['otherfields'].append({'name': cell, 'value': ''})
        output_list = []
        for cell in 'locationdate_dt location_s crate_s'.split(' '):
            if cell in r:
                if cell == 'location_s' and searchterm != '':
                    r[cell] = r[cell].replace(searchterm, '<span class="error">%s</span>' % searchterm)
                output_list.append(str(r[cell]).replace(' 19:00:00+00:00', ''))
            else:
                output_list.append(' ')
        locations[csid].append(' - '.join(output_list))

    for csid in objects.keys():
        row = objects[csid]
        row['otherfields'].append({'name' :'locations', 'value': sorted(locations[csid], reverse=True), 'multi': 2})
        # for cell in 'objectumber_s location_s crate_s locationdate_dt objectcount_s storagelocation_s computedcrate_s'.split(' '):
        results.append(row)

    context['labels'] = 'Musuem Number;Object Name;Count;Locations (date, location, crate)'.split(';')
    context['items'] = results
    context['querystring'] = querystring
    context['core'] = solr_core
    context['time'] = '%8.3f' % (time.time() - elapsedtime)
    return context
