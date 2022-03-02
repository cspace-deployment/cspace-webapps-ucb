__author__ = 'jblowe'

import re
import logging

import requests
import datetime
import xml.etree.ElementTree as ET

from django.contrib.auth.decorators import login_required
from django.shortcuts import render

# Get an instance of a logger, log some startup info
logger = logging.getLogger(__name__)
logger.info('%s :: %s :: %s' % ('x3dviewer startup', '-', '-'))

from common import cspace
from cspace_django_site.main import cspace_django_site

config = cspace_django_site.getConfig()
TITLE = 'Review recent x3d images'

size_limit = 60
page = 0


def make_x3d_url(blobcsid):
    return f'https://webapps.cspace.berkeley.edu/pahma/imageserver/blobs/{blobcsid}/content'
    # return "https://cspace-prod-02.ist.berkeley.edu/pahma_nuxeo/data/%s/%s/%s" % (md5[0:2], md5[2:4], md5)


def getblobs(request):
    connection = cspace.connection.create_connection(config, request.user)
    search_term = f'cspace-services/blobs?kw=x3d&sortBy=collectionspace_core:updatedAt+DESC&pgNum={page}&pgSz={size_limit}&wf_deleted=false'
    logger.info('%s :: %s' % ('x3dviewer', search_term))
    (url, data, statusCode, elapsedtime) = connection.make_get_request(search_term)
    blobs = ET.fromstring(data.decode("utf-8"))
    md5_keys = []
    for blob_csid in blobs.findall('.//csid'):
        (url, b, statusCode, elapsedtime) = connection.make_get_request(f'cspace-services/blobs/{blob_csid.text}')
        blob_record = ET.fromstring(b.decode("utf-8"))
        x3d_info = [blob_record.find('.//%s' % x).text for x in 'digest name uri digest length updatedAt'.split(' ')]
        x3d_info = x3d_info + [make_x3d_url(blob_csid.text), blob_csid.text]
        md5_keys.append(x3d_info)
    return md5_keys


@login_required()
def x3dviewer(request):
    if 'csid' in request.GET:
        csid = request.GET['csid']
        name = request.GET['name']
        x3d_url = make_x3d_url(csid)
        logger.info('%s :: x3d %s' % ('x3dviewer', csid))
        return render(request, 'x3dviewer.html', {'apptitle': TITLE, 'csid': csid, 'name': name, 'x3d_url': x3d_url})

    else:
        labels = 'X3D rendering,Blob Record,MD5 key,Size,Updated At,Raw X3D file'.split(',')
        md5_keys = getblobs(request)
        return render(request, 'x3dviewer.html', {'apptitle': TITLE, 'labels': labels, 'md5_keys': md5_keys})
