import re
import time
import csv
import logging
from .models import AdditionalInfo
from initialsetup import appLayout, APPS, institution, deployment, suggestions, VERSION
import heavylifting
from common.utils import loginfo

loginfo('%s :: %s :: %s' % ('toolbox startup', '-', '-'), '', {}, {})


def setconstants(context, appname):
    context['timestamp'] = time.strftime("%b %d %Y %H:%M:%S", time.localtime())
    context['searchrows'] = range(1, 4)
    context['searchcolumns'] = range(1, 4)
    context['apptitle'] = APPS[appname][0]
    context['appname'] = appname
    context['suggestions'] = suggestions
    context['institution'] = institution
    context['version'] = VERSION
    context['additionalInfo'] = AdditionalInfo.objects.filter(live=True)
    # context['device'] = devicetype(request)
    context['device'] = 'other'
    # insert a nav bar item to enable user to switch to a different tool
    context['extra_nav'] = {'href': './', 'id': 'switchtool', 'name': 'Switch Tool'}

    return context


def getfromXML(element, xpath):
    result = element.find(xpath)
    if result is None: return ''
    result = '' if result.text is None else result.text
    result = re.sub(r"^.*\)'(.*)'$", "\\1", result)
    return result


def dispatch(request, context, state):
    # data requests are special (render json, not html)
    if state == 'data':
        context = heavylifting.getData(context, request)

    else:
        # do the heavy lifting
        if 'start' in state:
            # context = heavylifting.doSearch(context, request)
            pass
        elif 'review' in state:
            context = heavylifting.doReview(context, request)
        elif 'enumerate' in state:
            context = heavylifting.doEnumerate(context, request)
        elif 'update' in state:
            context = heavylifting.doUpdate(context, request)
        elif 'movecheck' in state:
            context = heavylifting.doMovecheck(context, request)
        elif 'save' in state:
            context = heavylifting.doSave(context, request)
        elif 'activity' in state:
            context = heavylifting.doActivity(context, request)

            # if not 'items' in context:
            #     context['error'] = 'no items'
            # else:
            #     context['items'] =context['items']
            #     context['labels'] = context['labels']

    return context


def handleJSONrequest(context, request):
    try:
        state = request['state']
        appname = request['appname']
        x = appLayout
        if 'fieldset' in request and state == 'review':
            context = {'applayout': appLayout[request['fieldset']][state], 'appname': request['appname']}
        else:
            context = {'applayout': appLayout[appname][state],'appname': request['appname']}
        context = dispatch(request, context, state)
        # context['nextstate'] = appLayout[app][state]['nextstate']
    except:
        context['error'] = 'no app or state for these values'
    return context


