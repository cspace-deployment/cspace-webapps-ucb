__author__ = 'rjaffe (after jblowe\'s "imageserver")'

from django.contrib.auth.decorators import login_required
from django.http import HttpResponse

from os import path
from common import cspace # we use the config file reading function
from cspace_django_site import settings
from publicsearch.utils import doSearch
from common.utils import loginfo

from os import path
import urllib
import time
import logging
import re


#@login_required()
def get_entity(request, entitytype, responsemimetype):
    """ Connects to CollectionSpace server, makes request to cspace-services RESTful API.


    Returns xml payload or images.

    :param request:
    :param entitytype:
    :param responsemimetype:
    :return:
    """

    config = cspace.getConfig(path.join(settings.BASE_DIR, 'config'), 'eloan')
    username = config.get('connect', 'username')
    password = config.get('connect', 'password')
    hostname = config.get('connect', 'hostname')
    realm = config.get('connect', 'realm')
    protocol = config.get('connect', 'protocol')
    port = config.get('connect', 'port')
    port = ':%s' % port if port else ''

    server = protocol + "://" + hostname + port

    passman = urllib.request.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib.request.HTTPBasicAuthHandler(passman)
    opener = urllib.request.build_opener(authhandler)
    urllib.request.install_opener(opener)
    url = "%s/cspace-services/%s" % (server, entitytype)
    #loginfo('eloan', "<p>%s</p>" % url, {}, {})
    elapsedtime = 0

    # Get an instance of a logger, log some startup info
    logger = logging.getLogger(__name__)
    logger.info('%s :: %s :: %s' % ('eloan startup', '-', '%s' % server))

    try:
        elapsedtime = time.time()
        f = urllib.request.urlopen(url)
        data = f.read()
        elapsedtime = time.time() - elapsedtime
    except urllib.request.URLError as e:
        if hasattr(e, 'reason'):
            loginfo('eloan', 'We failed to reach a server.', {}, {})
            loginfo('eloan', 'Reason: ', e.reason, {})
            return HttpResponse(status=e.code)
        else:
            loginfo('eloan', 'The server couldn\'t fulfill the request.', {}, {})
            loginfo('eloan', 'Error code: ', e.code, {})
    else:
        return HttpResponse(data, content_type=responsemimetype)

def build_solr_query(solr_server, solr_core, solr_queryparam_key, solr_queryparam_value):
    """
    Takes solr query information, searches against ucjeps_project publicsearch portal.


    Returns search results.

    :param solr_server:
    :param solr_core:
    :param solr_queryparam_key:
    :param solr_queryparam_value:
    :return: results:
    """
    query_dictionary = {solr_queryparam_key: solr_queryparam_value, 'displayType': 'full', 'maxresults': '2000'}
    solr_context = {'searchValues': query_dictionary}
    # from publicsearch/utils.py
    results = doSearch(solr_server, solr_core, solr_context)
    return results

def getInstitutionCodefromDisplayName(element,xpath):
    result = element.find(xpath)
    if result is None: return ''
    result = '' if result.text is None else result.text
    if re.match(r".*:item:name\(.+?\)'.*\).*'$", result):
        result = re.sub(r"^.*:item:name\(.+?\)'.*\((.*)\).*\'$", "\\1", result)
    else:
        result = ''
    return result

def getShortIdfromRefName(element,xpath):
    result = element.find(xpath)
    if result is None: return ''
    result = '' if result.text is None else result.text
    result = re.sub(r"^.*:item:name\((.+?)\).*\'$", "\\1", result)
    return result
