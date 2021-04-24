__author__ = 'jblowe'

from django.shortcuts import render, redirect
from django.http import HttpResponse
import csv
from django.conf import settings
from os import path
import time

from cspace_django_site.main import cspace_django_site
from common import cspace
from common import appconfig
from common.utils import devicetype

config = cspace_django_site.getConfig()
hostname = cspace.getConfigOptionWithSection(config,
                                             cspace.CONFIGSECTION_AUTHN_CONNECT,
                                             cspace.CSPACE_HOSTNAME_PROPERTY)

TITLE = 'Virtual Musuem'


def makeBin(n):
    if n < 50: return 1
    elif n < 800: return 2
    elif n < 3000: return 3
    elif n < 10000: return 4
    else: return 5


def getTMSlocations(locFile):
    try:
        stats = {}
        locations = {}
        objectCounts = {}
        roomCounts = {}
        museumNumbers = {}
        locMap = {}
        # locs = csv.reader(codecs.open(locFile,'rb','utf-8'),delimiter="\t")
        locs = csv.reader(open(locFile, 'r'), delimiter="\t")
        for row, values in enumerate(locs):
            # print values
            location = values[1]
            museumNumber = values[0].strip()
            if location not in locations: locations[location] = []
            # locations[loc].append(museumNumber)
            # museumNumbers[museumNumber] = loc
            locParts = location.split(',')
            if len(locParts) > 2:
                rest = locParts[2]
                isIn = False
                for lx in ['Hearst Gym, 30,', 'Regatta, A150,', 'Marchant, 180,']:
                    if lx in location: isIn = True
                if isIn:
                    aisle = rest.strip().split(' ')
                    loc = '%s,%s, %s' % (locParts[0], locParts[1], aisle[0])
                    rest = ' '.join(aisle[1:])
                else:
                    loc = '%s,%s' % (locParts[0], locParts[1])
                    rest = locParts[2]
                try:
                    objectCounts[loc] += 1
                except:
                    objectCounts[loc] = 1
                if loc in locMap:
                    if rest in locMap[loc]:
                        locMap[loc][rest] += 1
                    else:
                        locMap[loc][rest] = 1
                else:
                    locMap[loc] = {}
                    locMap[loc][rest] = 1

                combined = loc + ' ' + rest

                try:
                    roomCounts[combined][location] += 1
                except:
                    if combined not in roomCounts:
                        roomCounts[combined] = {}
                    roomCounts[combined][location] = 1

        return locations, museumNumbers, locMap, objectCounts, roomCounts, stats
    except:
        raise
        pass


locations,museumNumbers,locMap,objectCounts,roomCounts,stats = getTMSlocations('vp/locs.csv')

def index(request):
    context = {}
    context['version'] = appconfig.getversion()
    context['labels'] = 'name file'.split(' ')
    context['apptitle'] = TITLE
    context['hostname'] = hostname
    context['device'] = devicetype(request)
    context['timestamp'] = time.strftime("%b %d %Y %H:%M:%S", time.localtime())

    html = ''
    topLocs = sorted(locMap.keys())
    for i,l in enumerate(topLocs):
        #cols = int(math.log(objectCounts[l],2)/3)
        cols = makeBin(objectCounts[l])
        if cols == 0: cols = 1
        html +=  f'<div class="box col{cols}"><div class="show left" data-loc="{l}">{l}</div><div class="right">{objectCounts[l]}</div>'
        #  % (cols,l,objectCounts[l],cols,l)
        sublocs = sorted(locMap[l].keys())
        html +=  '''<div class="bottom" id="%s" style="display:none">''' % l
        for subloc in sublocs:
            combined = l + ' ' + subloc
            locCount = len(roomCounts[combined])
            html += '''<div class="show bottom" data-loc="%s"> %s %s ''' % (combined,subloc,locMap[l][subloc])
            html += '''<div class="locdetail" id="%s" style="display:none;"><i>%s</i>:<br/>%s locs, %s objs</div></div>''' % (combined,combined,locCount,locMap[l][subloc])
        html +=   '</div></div>'
    context['html'] = html

    try:
        alert_config = cspace.getConfig(path.join(settings.BASE_DIR, 'config'), 'alert')
        context['ALERT'] = alert_config.get('alert', 'ALERT')
        context['MESSAGE'] = alert_config.get('alert', 'MESSAGE')
    except:
        context['ALERT'] = ''

    return render(request, 'vp.html', context)


