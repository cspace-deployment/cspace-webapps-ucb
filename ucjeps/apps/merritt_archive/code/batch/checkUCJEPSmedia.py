#
# script to check list of files against:
#  - what's in cspace,
#  - format and filename patterns
#  - what's already archived

# python3 checkUCJEPSmedia.py snowcone1.txt 4solr.ucjeps.allmedia.csv 4solr.ucjeps.public.csv archived.csv checked.csv toarchive.csv > image_report.txt

import csv
import sys
import time
import traceback
import configparser
import re

from collections import defaultdict


def getRecords(rawFile, key):
    message = None
    try:
        f = open(rawFile, 'r', encoding='utf-8')
        csvfile = csv.reader(f, delimiter="\t")
    except IOError:
        message = 'Expected to be able to read %s, but it was not found or unreadable' % rawFile
    except:
        raise

    if not message:
        try:
            columns = 0
            records = []
            for row, values in enumerate(csvfile):
                records.append(values)
                if len(values) > columns:
                    columns = len(values)
            return records, columns
        except IOError:
            message = 'Could not read (or maybe parse) rows from %s' % rawFile
        except:
            raise

    if message is not None:
        print('MEDIA: Error! %s' % rawFile)
        print(f'MEDIA: {message}')
        sys.exit()


if __name__ == "__main__":

    if len(sys.argv) == 7:
        print("MEDIA: input file 1  (fully qualified path): %s" % sys.argv[1])
        print("MEDIA: input file 2  (fully qualified path): %s" % sys.argv[2])
        print("MEDIA: input file 3  (fully qualified path): %s" % sys.argv[3])
        print("MEDIA: input file 4  (fully qualified path): %s" % sys.argv[4])
        print("MEDIA: output file 1 (fully qualified path): %s" % sys.argv[5])
        print("MEDIA: output file 2 (fully qualified path): %s" % sys.argv[6])
    else:
        print()
        print(
            "usage: %s <findcommandresult> <cspacemedia> <cspaceaccessions> <archivedalready> <outputfile> <pipelinefile>" %
            sys.argv[0])
        print(
            "e.g.   %s findcommandresult.txt cspacemedia.csv cspaceaccessions.csv archived.csv outputfile.csv toarchive.csv" %
            sys.argv[0])
        print(
            "python3 %s snowcone1.txt 4solr.ucjeps.allmedia.csv 4solr.ucjeps.public.csv archived.csv checked.csv toarchive.csv > image_report.txt" %
            sys.argv[0])

        print()
        sys.exit(1)

    stats = defaultdict(int)
    records1, columns1 = getRecords(sys.argv[1], 1)
    print('MEDIA: %s columns and %s lines found in file 1: %s' % (columns1, len(records1), sys.argv[1]))
    stats[f'input: {sys.argv[1]}'] = len(records1)

    records2, columns2 = getRecords(sys.argv[2], 1)
    errors = 0
    media_info = {}
    for r in records2:
        if len(r) == 14:
            if r[4] != '':
                media_info[r[4]] = r
            else:
                print(r)
        else:
            print(r)
            errors += 1
    print('MEDIA: %s columns and %s lines found in file 2: %s' % (columns2, len(records2), sys.argv[2]))
    stats[f'input: {sys.argv[2]}'] = len(records2)

    records3, columns3 = getRecords(sys.argv[3], 1)
    errors = 0
    accession_info = {}
    for r in records3:
        if len(r) == 70:
            accession_info[r[2]] = r
        else:
            print(r)
            errors += 1
    print('MEDIA: %s columns and %s lines found in file 3: %s' % (columns3, len(records3), sys.argv[3]))
    stats[f'input: {sys.argv[3]}'] = len(records3)

    records4, columns4 = getRecords(sys.argv[4], 1)
    errors = 0
    archive_info = {}
    for r in records4:
        if len(r) == 1:
            archive_info[r[0]] = r
        else:
            print(r)
            errors += 1
    print('MEDIA: %s columns and %s lines found in file 4: %s' % (columns4, len(records4), sys.argv[4]))
    stats[f'input: {sys.argv[4]}'] = len(records4)

    # this is a copy of the input file decorated with what is known about each file
    outputfh = csv.writer(open(sys.argv[5], 'w'), delimiter="\t")
    # this is for the input file to the archiving pipeline
    outputf2 = csv.writer(open(sys.argv[6], 'w'), delimiter="\t")

    # the first row of the file is a header
    columns = records2[0]
    del records2[0]
    outputfh.writerow(
        'accession_number filename filepath ok_to_archive image_found accession_found reason'.split(' ') + columns)

    filenames = {}
    filepaths = {}
    accession_numbers = defaultdict(list)
    seen = {}
    for i, r in enumerate(records1):
        ok_to_archive = True
        reason = []
        if len(r) == 0:
            print(f'skipping record {i}, empty')
            continue
        if r[0] == '':
            print(f'skipping record {i}, filepath is empty')
            continue
        filepath = r[0]
        filename = filepath.split('/')[-1]
        # normalize filename before check for accession number
        accession_number = filename.replace('-', '_').replace(' ', '_')
        # break on first period (presumably, before the extension)
        accession_number = accession_number.split('.')[0]
        # break on first underscore (some filenames have extra stuff after number)
        accession_number = accession_number.split('_')[0]
        # take the string after the last . and see if it is an extension
        extension = filepath.split('.')[-1].upper()
        if not extension in 'JPG TIF CR2'.split(' '):
            extension = 'unknown'
        # only CR2s are currently 'archivable'. everything else gets reviewed later
        if not extension == 'CR2':
            ok_to_archive = False
            reason.append('not CR2')
        stats[f'extension: {extension}'] += 1
        prefix = re.match(r'^([A-Z]+)', accession_number)
        if prefix and prefix[0] in ('UC JEPS GOD JOMU HREC BFRS').split(' '):
            stats['format check: has valid prefix'] += 1
        else:
            stats['format check: doesnt have valid prefix'] += 1
            reason.append('invalid prefix')
            ok_to_archive = False
        if filename in seen:
            seen[filename] += 1
            reason.append('duplicate')
            stats['filename duplicated'] += 1
            ok_to_archive = False
        else:
            seen[filename] = 1
        if filename in archive_info:
            archive_status = 'in archive already'
            ok_to_archive = False
            reason.append('archived already')
        else:
            archive_status = 'in archive not yet'
        stats[archive_status] += 1
        if ok_to_archive:
            stats['archivable: yes'] += 1
        else:
            stats['archivable: nope'] += 1
        if extension not in accession_numbers[accession_number]:
            accession_numbers[accession_number].append(extension)
        filenames[filepath] = (accession_number, filename, filepath, ok_to_archive, ','.join(reason))
        filepaths[filename] = filepath

    stats['filenames'] = len(filenames)

    stats['image found in cspace'] = 0
    stats['image not in cspace'] = 0
    stats['accession exists'] = 0
    stats['accession not found'] = 0
    for finfo in filenames:
        (accession_number, filename, filepath, ok_to_archive, reason) = filenames[finfo]
        if accession_number in accession_info:
            accession_exists = 'accession exists'
        else:
            accession_exists = 'accession not found'
        stats[accession_exists] += 1
        if filename in media_info:
            media_status = 'image in cspace'
            stats['image found in cspace'] += 1
            media_chunk = media_info[filename]
        else:
            media_status = 'image not in cspace'
            stats['image not in cspace'] += 1
            media_chunk = ['N/A']
        if ok_to_archive:
            outputf2.writerow([filepath])
        outputfh.writerow(list(filenames[finfo])[0:4] + [media_status, accession_exists, reason] + media_chunk)
        stats[f'{accession_exists} and {media_status}'] += 1

    # calculate number of image formats available for each accession number
    membership = defaultdict(int)
    for a in accession_numbers:
        membership[str(sorted(accession_numbers[a]))] += 1

    for m in membership:
        stats[f'derivatives: {m}'] = membership[m]

    # print run statistics
    print()
    print("Run statistics")
    print()
    for s in sorted(stats):
        print(f'{s} {stats[s]}')
