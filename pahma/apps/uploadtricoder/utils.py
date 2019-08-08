import csv
import codecs
import re
import json
import logging
from xml.sax.saxutils import escape
import hashlib

from common import cspace  # we use the config file reading function
from common.utils import loginfo
from cspace_django_site import settings
from os import path, listdir
from os.path import isfile, isdir, join

config = cspace.getConfig(path.join(settings.BASE_DIR, 'config'), 'uploadtricoder')
TRICODERDIR = config.get('files', 'directory')
POSTBLOBPATH = config.get('info', 'postblobpath')
TITLE = config.get('info', 'apptitle')
FILEPATH = path.join(TRICODERDIR, '%s')
SERVERINFO = {
    'serverlabelcolor': config.get('info', 'serverlabelcolor'),
    'serverlabel': config.get('info', 'serverlabel')
}


if isdir(TRICODERDIR):
    loginfo('tricoder',"Using %s as working directory for images and metadata files" % TRICODERDIR, {}, {})
else:
    loginfo('tricoder',"%s is not an existing directory, using /tmp instead" % TRICODERDIR, {}, {})
    TRICODERDIR  = '/tmp'


# Get an instance of a logger, log some startup info
logger = logging.getLogger(__name__)


def get_tricoder_file(directory,tricoder_filenumber):
    return (FILEPATH % '%s/%s') % (directory,tricoder_filenumber)


def tricoder_filesummary(tricoder_filestats):
    result = [0, 0, 0, []]
    for tricoder_filename, status, count, filenames in tricoder_filestats:
        if 'pending' in status:
            result[0] = count - 1
        if 'submitted' in status:
            result[0] = count - 1
            inputfiles = filenames
        if 'ingested' in status:
            result[1] = count
            try:
                result[2] = result[0] - result[1]
                result[3] = [image for image in inputfiles if image not in filenames and image != 'name']
            except:
                pass
    return result


def get_tricoder_filelist(directory):
    tricoder_filepath = FILEPATH % directory
    filelist = [f for f in listdir(tricoder_filepath) if isfile(join(tricoder_filepath, f)) and 'barcode.' in f]
    tricoder_filedict = {}
    errors = []
    for f in sorted(filelist):
        linecount, tricodertypes = checkFile(join(tricoder_filepath, f))
        counts = [0,0,0,0]
        subtotal = 0
        for i,recordtype in enumerate('M R C'.split(' ')):
            for t in tricodertypes:
                if '"%s"' % recordtype in t:
                    counts[i] += 1
                    subtotal += 1
        counts[3] = subtotal
        tricoder_filedict[f] = counts
    tricoder_filelist = [[tricoder_filekey, False, tricoder_filedict[tricoder_filekey]] for tricoder_filekey in sorted(tricoder_filedict.keys(), reverse=True)]
    return tricoder_filelist[0:500], errors, len(tricoder_filelist), len(errors)


def checkFile(filename):
    file_handle = open(filename)
    lines = file_handle.read().splitlines()
    recordtypes = [f.split(",")[0] for f in lines]
    return len(lines), recordtypes


def getQueue(tricoder_filetypes):
    return [x for x in listdir(FILEPATH % '') if '%s.csv' % tricoder_filetypes in x]


def getCSID(objectnumber):
    # dummy function, for now
    objectCSID = objectnumber
    return objectCSID


# following function borrowed from Django docs, w modifications
def handle_uploaded_file(f):
    destination = open(path.join(TRICODERDIR, 'input/%s') % f.name, 'wb+')
    with destination:
        for chunk in f.chunks():
            destination.write(chunk)
    destination.close()
