import os, sys, time

header = 'name|size|objectnumber|date|creator|contributor|rightsholder|imagenumber|handling|approvedforweb|description'

description = 'automatically generated pdf'
handling = ''
size = ''
date = time.strftime("%Y/%m/%dT%H:%M:%S", time.localtime())

rootDir = sys.argv[1]
for dirName, subdirList, fileList in sorted(os.walk(rootDir)):
    print('directory: %s' % dirName)
    job_file = open(f'{rootDir}/{dirName}.step1.csv', 'w')
    job_file.write(header + '\n')
    for name in sorted(fileList):
        doc_id = name.replace('.pdf', '')
        job_file.write(f'{name}|{size}|{doc_id}|{date}|||||{handling}|on|{description}\n')
        print('\t%s' % name)
    job_file.close()
