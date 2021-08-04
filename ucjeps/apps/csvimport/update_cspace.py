import codecs
import sys
import time
import traceback
import re
from lxml.etree import parse, fromstring, ElementTree
from utils import map_items, loginfo

sys.path.append("../../ucjeps")

def update_cspace(action, mapping, inputRecords, recordtypes, file_header, outputfh, service, in_progress, keyrow):
    recordsprocessed = 0
    successes = 0
    failures = 0

    for input_data in inputRecords:

        if recordsprocessed % 1000 == 0:
            in_progress.write("%s records of %s output %s\n" % (recordsprocessed, len(inputRecords), time.strftime("%b %d %Y %H:%M:%S", time.localtime())))
            in_progress.flush()

        cspaceElements = ['', '']
        elapsedtimetotal = time.time()
        try:
            input_dict = map_items(input_data, mapping, recordtypes, file_header, keyrow)
            #cspaceElements = DWC2CSPACE(action, xmlTemplate, xmlTemplateTree, input_dict, config, uri)
            del cspaceElements[2]
            cspaceElements.append('%8.2f' % (time.time() - elapsedtimetotal))
            # loginfo('csvimport', "item created: %s, csid: %s %s" % tuple(cspaceElements), {}, {})
            if cspaceElements[1] != '':
                successes += 1
            else:
                loginfo('csvimport', cspaceElements, {}, {})
                raise Exception(f'DWC2CSPACE did not return a valid result for {cspaceElements}')
            outputfh.writerow(cspaceElements)
            # flush output buffers so we get a much data as possible if there is a failure
            # outputfh.flush()
            sys.stdout.flush()
        except Exception:
            loginfo('csvimport', "Exception!", {}, {})
            loginfo('csvimport', "-"*60, {}, {})
            traceback.print_exc(file=sys.stdout)
            loginfo('csvimport', "-"*60, {}, {})
            loginfo('csvimport', "item update failed for object number '%s', %8.2f" % (cspaceElements[0], (time.time() - elapsedtimetotal)), {}, {})
            failures += 1
        recordsprocessed += 1
    return recordsprocessed, successes, failures
