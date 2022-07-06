__author__ = 'jblowe'

import random
import logging
import collections

from django.contrib.auth.decorators import login_required
from django.shortcuts import render

from common.utils import doSearch, setConstants, loginfo
from common.appconfig import loadConfiguration, loadFields, getParms
from common import cspace  # we use the config file reading function
from cspace_django_site import settings
from os import path
from .models import AdditionalInfo

config = cspace.getConfig(path.join(settings.BASE_DIR, 'config'), 'curator')

# read common config file
common = 'common'
prmz = loadConfiguration(common)
loginfo('curator', 'Configuration for %s successfully read' % common, {}, {})

searchConfig = cspace.getConfig(path.join(settings.BASE_DIR, 'config'), 'curator')
prmz.FIELDDEFINITIONS = searchConfig.get('curator', 'FIELDDEFINITIONS')

# add in the the field definitions...
prmz = loadFields(prmz.FIELDDEFINITIONS, prmz)

# override a couple parameters for this app
prmz.MAXRESULTS = int(searchConfig.get('curator', 'MAXRESULTS'))
prmz.TITLE = searchConfig.get('curator', 'TITLE')

loginfo('curator', 'Configuration for %s successfully read' % 'curator', {}, {})

# Get an instance of a logger, log some startup info
logger = logging.getLogger(__name__)
logger.info('%s :: %s :: %s' % ('curator startup', '-', '%s | %s' % (prmz.SOLRSERVER, prmz.IMAGESERVER)))


def random_sample(choices, bins, label, number_of_items):
    crowd = random.sample(choices, 1)
    crowd_name = crowd[0][0]

    x = random.sample(bins[label][crowd_name], number_of_items)
    return x, crowd_name


def organize(items, number_of_items, sets):
    questions = []
    bins = collections.defaultdict(dict)
    for x in items:
        for i in x['otherfields']:
            if i['value'] == '': continue
            if not i['label'] in bins:
                bins[i['label']] = collections.defaultdict(list)
            if type(i['value']) == type([]):
                bins[i['label']][i['value'][0]].append(x)
            else:
                bins[i['label']][i['value']].append(x)
    game_bins = collections.defaultdict(dict)
    for i, label in enumerate(bins):
        if i >= sets: break
        possible = []
        oddman = []
        for b in bins[label]:
            if len(bins[label][b]) >= number_of_items:
                possible.append([b, len(bins[label][b])])
            else:
                oddman.append([b, len(bins[label][b])])
        if len(possible) > 0 and len(oddman) > 0:
            crowd, label_for_crowd = random_sample(possible, bins, label, number_of_items - 1)
            oddman, label_for_oddman = random_sample(oddman, bins, label, 1)
            crowd.append(oddman[0])
            crowd = random.sample(crowd, len(crowd))
            correct = crowd.index(oddman[0]) + 1
            game_bins[label] = crowd, label_for_crowd, label_for_oddman, correct
        else:
            pass

    # for label in game_bins:
    #     # just trying to select a nice random subset; sorry it's so complicated
    #     v = bins[label].keys()
    #     select = random.sample(range(len(v) - 1), number_of_items)
    #     keys_to_use = [list(v)[k] for k in select]
    #     bins[label] = [bins[label][k] for k in keys_to_use]
    #     final_bins = dict(bins)
    final_bins = dict(game_bins)
    # for x in final_bins:
    #    final_bins[x] = [y[0] for y in final_bins[x]]
    return final_bins


def curator(request):
    context = {'additionalInfo': AdditionalInfo.objects.filter(live=True),
               'maxresults': prmz.MAXRESULTS}

    if request.method == 'GET':
        context['score'] = 0
        context['wrong'] = 0
        context['right'] = 0
        context['start'] = 0

    if 'pane' in request.POST:
        if request.POST['pane'] == 'guess':
            context['searchValues'] = request.POST
            context['count'] = 0
            prmz.MAXFACETS = 20
            # default display type is Grid
            if 'score' in request.POST:
                context['score'] = int(request.POST['score'])
                context['right'] = int(request.POST['right'])
                context['wrong'] = int(request.POST['wrong'])
            if 'keyword' in request.POST:
                context['keyword'] = request.POST['keyword']
            if 'accession' in request.POST:
                context['accession'] = request.POST['accession']
                context['maxresults'] = 1
            if 'pixonly' in request.POST:
                context['pixonly'] = 'true'
            else:
                context['pixonly'] = 'false'
            if 'submit' in request.POST:
                if "Seed" == request.POST['submit'] or "Metadata" in request.POST['submit']:
                    context['resultType'] = 'oddthingout'
                elif "selectfields" in request.POST['submit']:
                    context['resultType'] = 'question'
                elif "Start" in request.POST['submit'] or "Next" in request.POST['submit']:
                    context['resultType'] = 'question'
                elif "Images" in request.POST['submit']:
                    context['resultType'] = 'images'
                    context['pixonly'] = 'true'
                elif "Lucky" in request.POST['submit']:
                    context['resultType'] = 'metadata'
                    context['maxresults'] = 1
                else:
                    context['resultType'] = 'metadata'

                loginfo('curator', 'start curator search', context, request)
                context = doSearch(context, prmz, request)
                context['start'] = int(request.POST['start']) + 1
                if context['count'] >= 1000:
                    number_in_play = min(prmz.MAXRESULTS, context['count'])
                    number_of_items = 6
                    max_number_of_sets = 15
                    context['questions'] = organize(context['items'], number_of_items, max_number_of_sets)
                    #context['questions'] = organize(context['items'], 6, int(request.POST['sets']))
                else:
                    context['errormsg'] = 'need to find at least 1000 objects to play!'
                # record_range = random.sample(range(number_in_play - 1), number_of_items)
                # context['items'] = [context['items'][i] for i in record_range]
                pass
                # context['items'] = context['items'][0]

        return render(request, 'curator.html', context)

    else:
        return render(request, 'curator.html', context)
