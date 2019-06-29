__author__ = 'jblowe, amywieliczka'

import time, datetime
from os import path
import logging

from django.contrib.auth.decorators import login_required
from django.shortcuts import render, render_to_response, redirect
from django.template.loader import render_to_string
from django.http import HttpResponse, HttpResponseRedirect
from django.contrib import messages
from django import forms
from cspace_django_site.main import cspace_django_site
from common.utils import writeCsv, doSearch, setupGoogleMap, setupBMapper, computeStats, setupCSV, setDisplayType, setConstants, loginfo
# from common.utils import CSVPREFIX, CSVEXTENSION
from common.appconfig import loadFields, loadConfiguration
from common import cspace  # we use the config file reading function
from .models import AdditionalInfo

from cspace_django_site import settings

# read common config file
prmz = loadConfiguration('common')
print 'Configuration for common successfully read'

# on startup, setup this webapp layout...
config = cspace.getConfig(path.join(settings.BASE_PARENT_DIR, 'config'), 'osteology')
fielddefinitions = config.get('search', 'FIELDDEFINITIONS')
prmz = loadFields(fielddefinitions, prmz)

# Get an instance of a logger, log some startup info
logger = logging.getLogger(__name__)
logger.info('%s :: %s :: %s' % ('osteology portal startup', '-', '%s | %s | %s' % (prmz.SOLRSERVER, prmz.IMAGESERVER, prmz.BMAPPERSERVER)))

def gatherosteoparms(searchvalues):
    aggregate = []
    search_keys = []
    for key in searchvalues.keys():
        if key == 'csrfmiddlewaretoken' : continue
        if searchvalues[key] == '': continue
        searchkey = key.replace('csc-osteology-','')
        search_keys.append(searchkey)
        aggregate.append('aggregate_ss:"%s"' % searchkey.lower())
        #aggregate.append(searchkey.lower())
        #aggregate.append('%s=%s' % (searchkey.lower(), searchvalues[key]))
    # e.g.: aggregate_ss:"cranium=3" OR  aggregate_ss:"cranium=0"
    return aggregate, search_keys
    #return {'aggregate': ' '.join(aggregate), 'aggregate_qualifier': 'special'}

def direct(request):
    return redirect('search/')


@login_required()
def search(request):
    if request.method == 'GET' and request.GET != {}:
        context = {'searchValues': dict(request.GET.iteritems())}
        context = doSearch(context, prmz, request)
    else:
        context = setConstants({}, prmz, request)

    loginfo(logger, 'start search', context, request)
    context['additionalInfo'] = AdditionalInfo.objects.filter(live=True)
    context['extra_nav'] = {'href': '../skeleton', 'id': 'skeleton', 'name': 'Skeleton'}
    return render(request, 'search.html', context)


@login_required()
def skeleton(request):
    if request.method == 'GET' and request.GET != {}:
        # context = {'searchValues': dict(request.GET.iteritems())}
        aggregate, search_keys = gatherosteoparms(dict(request.GET.iteritems()))
        requestObject = {'querystring': (' OR '.join(aggregate)), 'url': 'url', 'special': 'true'}
        context = {'searchValues': requestObject}
        context['aggregate'] = search_keys
        context = doSearch(context, prmz, request)
    else:
        context = setConstants({}, prmz, request)

    loginfo(logger, 'start skeleton search', context, request)
    context['additionalInfo'] = AdditionalInfo.objects.filter(live=True)
    context['extra_nav'] = {'href': '../search', 'id': 'search', 'name': 'Metadata Search'}
    return render(request, 'osteo.html', context)


@login_required()
def retrieveResults(request):
    if request.method == 'POST' and request.POST != {}:
        requestObject = dict(request.POST.iteritems())
        form = forms.Form(requestObject)

        if form.is_valid():
            context = {'searchValues': requestObject}
            context = doSearch(context, prmz, request)

        loginfo(logger, 'results.%s' % context['displayType'], context, request)
        return render(request, 'searchResults.html', context)