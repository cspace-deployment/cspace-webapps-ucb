__author__ = 'jblowe, amywieliczka'

import time, datetime
from os import path
import logging
import json

#from cspace_django_site.profile import profile

from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect
from django.template.loader import render_to_string
from django.http import HttpResponse, HttpResponseRedirect
from django.views.decorators.csrf import csrf_exempt
from django.contrib import messages
from django import forms
from cspace_django_site.main import cspace_django_site
from common.utils import writeCsv, doSearch, setConstants, loginfo
from common.utils import setupGoogleMap, setupBMapper, computeStats, setupCSV, setup4PDF
from common.utils import setup4Print, setDisplayType

# from common.utils import CSVPREFIX, CSVEXTENSION
from common.appconfig import loadFields, loadConfiguration
from common import cspace  # we use the config file reading function
from .models import AdditionalInfo

from cspace_django_site import settings

# read common config file
prmz = loadConfiguration('common')
loginfo('publicsearch', 'Configuration for common successfully read', {}, {})

# on startup, setup this webapp layout...
config = cspace.getConfig(path.join(settings.BASE_DIR, 'config'), 'search')
fielddefinitions = config.get('search', 'FIELDDEFINITIONS')
prmz = loadFields(fielddefinitions, prmz)

# Get an instance of a logger, log some startup info
logger = logging.getLogger(__name__)
logger.info('%s :: %s :: %s' % ('publicsearch portal startup', '-', '%s | %s | %s' % (prmz.SOLRSERVER, prmz.IMAGESERVER, prmz.BMAPPERSERVER)))


def direct(request):
    return redirect('publicsearch/')


def accesscontrolalloworigin(stuff2return):
    response = HttpResponse(stuff2return)
    response["Access-Control-Allow-Origin"] = "*"
    return response

def publicsearch(request):
    if request.method == 'GET' and request.GET != {}:
        context = {'searchValues': request.GET}
        context = doSearch(context, prmz, request)

    else:
        context = setConstants({}, prmz, request)

    loginfo('publicsearch', 'start search', context, request)
    context['additionalInfo'] = AdditionalInfo.objects.filter(live=True)
    return render(request, 'search.html', context)


# @profile("retrieve.prof")
def retrieveResults(request):
    if request.method == 'POST' and request.POST != {}:
        requestObject = request.POST
        form = forms.Form(requestObject)

        if form.is_valid():
            context = {'searchValues': requestObject}
            context = doSearch(context, prmz, request)

            loginfo('publicsearch', 'results.%s' % context['displayType'], context, request)
            return render(request, 'searchResults.html', context)


@csrf_exempt
def facetJSON(request):
    if request.method == 'GET' and request.GET != {}:
        requestObject = request.POST
        form = forms.Form(requestObject)

        if form.is_valid():
            context = {'searchValues': requestObject}
            context = doSearch(context, prmz, request)

            loginfo('publicsearch', 'results.%s' % context['displayType'], context, request)
            #del context['FIELDS']
            #del context['facets']
            if not 'items' in context:
                return accesscontrolalloworigin(json.dumps('error'))
            else:
                return accesscontrolalloworigin(json.dumps({'facets': context['facets'],'fields': context['fields']}))
    else:
        return accesscontrolalloworigin(json.dumps('no data seen'))


@csrf_exempt
def retrieveJSON(request):
    if request.method == 'GET' and request.GET != {}:
        requestObject = request.GET
        form = forms.Form(requestObject)

        if form.is_valid():
            context = {'searchValues': requestObject}
            context = doSearch(context, prmz, request)

            loginfo('publicsearch', 'results.%s' % context['displayType'], context, request)
            #del context['FIELDS']
            #del context['facets']
            if not 'items' in context:
                return accesscontrolalloworigin(json.dumps('error'))
            else:
                return accesscontrolalloworigin(json.dumps({'items': context['items'],'labels': context['labels']}))
    else:
        return accesscontrolalloworigin(json.dumps('no data seen'))


def JSONentry(request): 
    context = setConstants({}, prmz, request)
    
    return render(request, 'json_searchentry.html', context)


def bmapper(request):
    if request.method == 'POST' and request.POST != {}:
        requestObject = request.POST
        form = forms.Form(requestObject)

        if form.is_valid():
            context = {'searchValues': requestObject}
            context = setupBMapper(request, requestObject, context, prmz)

            loginfo('publicsearch', 'bmapper', context, request)
            return HttpResponse(context['bmapperurl'])


def gmapper(request):
    if request.method == 'POST' and request.POST != {}:
        requestObject = request.POST
        form = forms.Form(requestObject)

        if form.is_valid():
            context = {'searchValues': requestObject}
            context = setupGoogleMap(request, requestObject, context, prmz)

            loginfo('publicsearch', 'gmapper', context, request)
            return render(request, 'maps.html', context)


def dispatch(request):

    if request.method == 'POST' and request.POST != {}:
        requestObject = request.POST
        form = forms.Form(requestObject)

    if 'csv' in request.POST or 'downloadstats' in request.POST:

        if form.is_valid():
            try:
                context = {'searchValues': requestObject}
                csvformat, fieldset, csvitems = setupCSV(request, requestObject, context, prmz)
                loginfo('publicsearch', 'csv', context, request)

                # create the HttpResponse object with the appropriate CSV header.
                response = HttpResponse(content_type='text/csv')
                response['Content-Disposition'] = 'attachment; filename="%s-%s.%s"' % (prmz.CSVPREFIX, datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S"), prmz.CSVEXTENSION)
                return writeCsv(response, fieldset, csvitems, writeheader=True, csvFormat=csvformat)
            except:
                messages.error(request, 'Problem creating .csv file. Sorry!')
                context['messages'] = messages
                return publicsearch(request)

    elif 'pdf' in request.POST:

        if form.is_valid():
            try:
                context = {'searchValues': requestObject}
                loginfo('publicsearch', 'pdf', context, request)
                return setup4PDF(request, context, prmz)

            except:
                messages.error(request, 'Problem creating .pdf file. Sorry!')
                context['messages'] = messages
                return publicsearch(request)

    elif 'preview' in request.POST:
        messages.error(request, 'Problem creating print version. Sorry!')
        context = {'messages': messages}
        return publicsearch(request)


def statistics(request):
    if request.method == 'POST' and request.POST != {}:
        requestObject = request.POST
        form = forms.Form(requestObject)

        if form.is_valid():
            elapsedtime = time.time()
            try:
                context = {'searchValues': requestObject}
                loginfo('publicsearch', 'statistics1', context, request)
                context = computeStats(request, requestObject, context, prmz)
                loginfo('publicsearch', 'statistics2', context, request)
                context['summarytime'] = '%8.2f' % (time.time() - elapsedtime)
                # 'downloadstats' is handled in writeCSV, via post
                return render(request, 'statsResults.html', context)
            except:
                context['summarytime'] = '%8.2f' % (time.time() - elapsedtime)
                return HttpResponse('Please pick some values!')


def loadNewFields(request, fieldfile, prmx):
    loadFields(fieldfile + '.csv', prmx)

    context = setConstants({}, prmx, request)
    loginfo('publicsearch', 'loaded fields', context, request)
    return render(request, 'search.html', context)
