import csv
import codecs
import sys
import time
import re
from lxml.etree import parse, fromstring, ElementTree

# this "standalone" app nevertheless needs access to django bits in utils and common; add a path to help
sys.path.append("../../ucjeps")
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

from utils import load_mapping_file, validate_items, count_columns, getRecords, write_intermediate_files
from utils import add_to_cspace, count_stats, count_numbers, getConfig, find_keyfield, fixup, get_recordtypes
from update_cspace import update_cspace

CONFIGDIRECTORY = ''


def main():
    # header = "*" * 100

    if len(sys.argv) < 10:
        print
        print('need 9 arguments, or suitable placeholders:')
        print('%s <csv input file> <config file> <mapping file> <template> <validated file> <unvalidated file> <terms file> <action> <uri>' % sys.argv[0])
        sys.exit()

    # print(header)
    print("start time:        %s" % time.strftime("%b %d %Y %H:%M:%S", time.localtime()))
    print
    print("input  file:       %s" % sys.argv[1])
    print("config file:       %s" % sys.argv[2])
    print("mapping file:      %s" % sys.argv[3])
    print("template:          %s" % sys.argv[4])
    print("validated file:    %s" % sys.argv[5])
    print("unvalidated file:  %s" % sys.argv[6])
    print("terms file:        %s" % sys.argv[7])
    print("action:            %s" % sys.argv[8])
    print("uri:               %s" % sys.argv[9])
    # print(header)

    parameters_ok = True

    try:
        uri = sys.argv[9]
        uris = 'collectionobjects orgauthorities taxon'
        valid_uri = False
        for test_uri in uris.split(' '):
            if test_uri in uri:
                valid_uri = True
        if not valid_uri:
            print('Error! not a valid URI: %s' % uri)
            parameters_ok = False
    except:
        raise
        print("URI could not be understood: should be one of: %s" % uris)
        parameters_ok = False

    try:
        action = sys.argv[8]
        actions = 'count validate validate-add validate-new validate-update validate-both add update both'
        if not action in actions.split(' '):
            print('Error! not a valid action: %s' % action)
            parameters_ok = False
    except:
        print("action could not be understood: should be one of: %s" % actions)
        parameters_ok = False

    try:
        config = getConfig(sys.argv[2])

        print("hostname:          %s" % config.get('connect', 'hostname'))
        print("institution:       %s" % config.get('info', 'institution'))
        # print(header)
    except:
        print("could not get cspace server configuration (parameter 2)")
        parameters_ok = False

    try:
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            try:
                dataDict, inputRecords, lines, file_header, bad_rows = getRecords(f)
            except Exception as inst:
                print(inst)
                print
                print("could not get CSV records to load")
                raise
        if bad_rows[1] > 0:
            print('Error! %s %s' % (bad_rows[1], bad_rows[0]))
            print('rows: ',)
            print(','.join([str(b) for b in bad_rows[2]]))
            raise
        print('%s lines found in file %s' % (lines, sys.argv[1]))
    except:
        print("could not open or process %s" % sys.argv[1])
        parameters_ok = False

    try:
        # print("loading mapping file %s\n" % sys.argv[3])
        mapping, errors, constants = load_mapping_file(sys.argv[3])
        print('%s rows found in mapping file %s' % (len(mapping), sys.argv[3]))

        keyfield, keyrow = find_keyfield(mapping, file_header)

        if keyrow == -1:
            errors += 1
            print('no key column indicated in mapping file %s' % sys.argv[3])

        if errors != 0:
            print("terminating due to %s errors detected in mapping configuration" % errors)

            parameters_ok = False
    except:
        print("could not get mapping configuration %s" % sys.argv[3])
        parameters_ok = False

    try:
        with open(sys.argv[4], 'r', encoding='utf-8') as f:
            xmlTemplate = f.read()
            xmlTemplateTree = parse(sys.argv[4])
            # print(xmlTemplate)
    except:
        raise
        print("could not get template %s" % sys.argv[4])
        parameters_ok = False

    try:
        outputfh = csv.writer(open(sys.argv[5], 'w', encoding='utf-8'), delimiter="\t", quoting=csv.QUOTE_NONE, quotechar=chr(255),
                                escapechar='\\')
    except:
        print("could not open validated file for write %s" % sys.argv[5])
        parameters_ok = False

    try:
        nonvalidfh = csv.writer(open(sys.argv[6], 'w', encoding='utf-8'), delimiter="\t", quoting=csv.QUOTE_NONE, quotechar=chr(255),
                                escapechar='\\')
    except:
        print("could not open nonvalidated file for write %s" % sys.argv[6])
        parameters_ok = False

    try:
        termsfh = csv.writer(open(sys.argv[7], 'w', encoding='utf-8'), delimiter="\t", quoting=csv.QUOTE_NONE, quotechar=chr(255),
                                escapechar='\\')
    except:
        print("could not open terms file for write %s" % sys.argv[5])
        parameters_ok = False

    try:
        in_progress_file = re.sub(r'\..*?.csv','.inprogress.log', sys.argv[1])
        in_progress_file = re.sub(r'\.csv','.inprogress.log', in_progress_file)
        in_progress = open(in_progress_file, 'w', encoding='utf-8')
        in_progress.write("started at %s\n" % time.strftime("%b %d %Y %H:%M:%S", time.localtime()))
        in_progress.flush()
    except:
        print("could open a progress log")
        parameters_ok = False

    if not parameters_ok:
        print("bailed at:       %s" % time.strftime("%b %d %Y %H:%M:%S", time.localtime()))
        sys.exit(1)

    recordsprocessed = 0
    successes = 0
    failures = 0

    if action == 'count':
        stats = count_columns(inputRecords, file_header)
        print
        print('counts of types and tokens, with an indication of whether the field can be mapped into cspace')
        print
        print('cspace record type is %s' % uri)
        print
        print('%-30s %10s %10s' % tuple(stats[1]), end=' ')
        print(' %-25s %-15s' % ('cspace field', 'validation type'))
        print
        for s in stats[0]:
            print('%-30s %10s %10s' % tuple(s), end=' ')
            if s[0] in mapping:
                print(' %-25s %-15s' % (mapping[s[0]][0], mapping[s[0]][2]))
            else:
                print()
        print

        # create a copy of the input file, for further processing...
        outputfh.writerow(file_header)
        for i, input_data in enumerate(inputRecords):
            try:
                outputfh.writerow(input_data)
                recordsprocessed += 1
                successes += 1
            except Exception as inst:
                print('failed to write row %s of input data' % i)
                print(inst)
                print(('|').join(input_data))
                recordsprocessed += 1
                failures += 1


    elif 'validate' in action:

        validating_items, nonvalidating_items, stats, number_check= validate_items(mapping, constants,
                                                                                          inputRecords, file_header, uri,
                                                                                          in_progress, action, keyrow, keyfield)

        ok_count, bad_count, bad_values = count_stats(stats, mapping)
        not_found, found, total = count_numbers(number_check)

        # for the 'new' action, we want to switch things around a bit
        if action == 'validate-new':
            x = validating_items
            validating_items = fixup(nonvalidating_items, stats, file_header)
            nonvalidating_items = x
            x = not_found
            found = not_found
            not_found = x
            bad_count = 0

        if bad_count != 0:
            print("validation failed (%s field(s) had %s value(s) in error)" % (bad_count, bad_values))
            # print("cowardly refusal to write invalid output file")
            # sys.exit(1)


        print(100 * '*')
        print("%s:  %s found, %s not found, %s total" % ('record keys', found, not_found, total))
        if action == 'validate-add':
            print('since this is an "add",')
            if found > 0:
                print(f'the{found} found keys represent *invalid* records: they already exist in CSpace')
            if not_found > 0:
                print(f'the records referring to the {not_found} keys will be added to CSpace')
        elif action == 'validate-update':
            print('since this is an "update",')
            if found > 0:
                print(f'the records referring to the {found} keys will be updated CSpace')
            if not_found > 0:
                print(f'the {not_found} keys represent *invalid* records: we could not find the records to update')
        print(100 * '*')
        print()

        recordsprocessed, successes, failures = write_intermediate_files(stats, validating_items, nonvalidating_items,
                                                                         constants, file_header, mapping,
                                                                         outputfh, nonvalidfh, termsfh, number_check,
                                                                         keyrow)

    elif action == 'add':
        keyfield, keyrow = find_keyfield(mapping, file_header)
        recordtypes = get_recordtypes()
        service = recordtypes[uri][2]
        recordsprocessed, successes, failures = add_to_cspace(action, mapping, inputRecords, recordtypes[uri], file_header, xmlTemplate, xmlTemplateTree, outputfh, service, in_progress, keyrow)

    elif action == 'update':
        keyfield, keyrow = find_keyfield(mapping, file_header)
        recordtypes = get_recordtypes()
        service = recordtypes[uri][2]
        recordsprocessed, successes, failures = update_cspace(action, mapping, inputRecords, recordtypes, file_header, outputfh, service, in_progress, keyrow)

    print("FINISHED %s records: %s processed, %s successful, %s failures" % (action, recordsprocessed, successes, failures))
    print()
    print("end time:        %s" % time.strftime("%b %d %Y %H:%M:%S", time.localtime()))

    in_progress.write("ended at %s\n" % time.strftime("%b %d %Y %H:%M:%S", time.localtime()))
    in_progress.close()


    # print(header)


if __name__ == "__main__":
    main()
