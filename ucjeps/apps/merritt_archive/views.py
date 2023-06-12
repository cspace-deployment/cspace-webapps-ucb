import os.path
from collections import defaultdict
from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect
from django import forms
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
import json
from django.conf import settings
from os import path, listdir
from os.path import isfile, isdir
import time
import csv
from .models import Transaction
#from .models import STATUSES
# JOB_STATUSES = 'new,ok,deferred,queued,archived,tidied'.split(',')
JOB_STATUSES = 'input diverted cr2s queued not_queued tiffs not_tiffs completed log'.split(' ')

from cspace_django_site.main import cspace_django_site
from common import cspace
from common import appconfig
from uploadmedia.utils import rendermedia, reformat
from uploadmedia.getNumber import getNumber
from common.utils import loginfo
# read common config file, just for the version info
from common.appconfig import loadConfiguration
prmz = loadConfiguration('common')

config = cspace_django_site.getConfig()
hostname = cspace.getConfigOptionWithSection(config,
                                             cspace.CONFIGSECTION_AUTHN_CONNECT,
                                             cspace.CSPACE_HOSTNAME_PROPERTY)

TITLE = 'Image Archiving Pipeline'

archiveConfig = cspace.getConfig(path.join(settings.BASE_DIR, 'config'), 'merritt_archive')
SOURCE_BUCKET = archiveConfig.get('archive', 'source_bucket')
TARGET_BUCKET = archiveConfig.get('archive', 'target_bucket')
PAGE_SIZE = int(archiveConfig.get('archive', 'page_size'))
JOB_DIR = archiveConfig.get('archive', 'job_dir')

# see https://merritt.cdlib.org/d/ark%3A%2F13030%2Fm55t8dtz/0/producer%2FMerritt-ingest-service-latest.pdf
@csrf_exempt
def callback(request, rest):
    if request.method == 'POST':
        loginfo('merritt_archive', f'merrit jobid: {rest}', {}, {})
        try:
            body_unicode = request.body.decode('utf-8')
            body = json.loads(body_unicode)
            loginfo('merritt_archive', f'merrit body: {body_unicode}', {}, {})
            primaryID = body['job:jobState']['job:primaryID']
            completionDate = body['job:jobState']['job:completionDate']
            localID = body['job:jobState']['job:localID']
            objectTitle = body['job:jobState']['job:objectTitle']
            packageName = body['job:jobState']['job:packageName']
            # if the package name is the name of the manifest, use it as the 'completed' file name
            if '.checkm' in packageName:
                job_name = packageName.replace('.checkm', '')
            else:
                # for now, we use 'today' as the job_name, until merritt updates the package name
                # to use the manifest file name
                job_name = 'mrt-' + time.strftime("%Y-%m-%d", time.localtime())

            # TODO: not sure why we have to specify the encoding here, but we do
            job_file = open(path.join(JOB_DIR, f'{job_name}.completed.csv'), 'a+', encoding='utf-8')
            job_writer = csv.writer(job_file, delimiter="\t")
            job_writer.writerow([localID, primaryID, objectTitle, completionDate])
            job_file.close()
            transaction = Transaction(status='archived',
                                      accession_number=getNumber(localID,'ucjeps')[1],
                                      transaction_date=completionDate,
                                      transaction_detail=primaryID,
                                      image_filename=localID)
            save_db(transaction)
            loginfo('merritt_archive', f'object archived: {job_name} / {primaryID} / {localID} / {objectTitle} / {completionDate}', {}, {})
        except:
            loginfo('merritt_archive', f'callback could not be processed {body_unicode}', {}, {})
    else:
        loginfo('merritt_archive', f'callback received, but was not a POST', {}, {})

    return HttpResponse()


def save_db(transaction):
    transaction.save(using = 'merritt_archive')


def archive_detail(request, pk):
    appList = [app for app in settings.INSTALLED_APPS if not "django" in app and not app in SOURCE_BUCKET]

    appList = sorted(appList)
    appList = [(app,path.join(settings.WSGI_BASE, app)) for app in appList]
    return appList


@login_required()
def index(request):
    context = {}
    context['version'] = appconfig.getversion()
    context['labels'] = 'name file'.split(' ')
    context['apptitle'] = TITLE
    context['timestamp'] = time.strftime("%b %d %Y %H:%M:%S", time.localtime())
    # context['statuses'] = JOB_STATUSES

    if request.method == 'POST' or request.method == 'GET':
        details = forms.Form(request.POST)
        if details.is_valid():
            #post = details.save(commit=False)
            #post.save()
            # return HttpResponse("data submitted successfully")
            if 'search' in details.data:
                find_transactions(request, context)
            elif 'checkjobs' in details.data:
                context['display'] = 'checkjobs'
            elif 'startjob' in request.GET:
                startjob(request, request.GET['startjob'])
            elif 'filename' in request.GET:
                show_archive_results(request, context)
            elif 'createjobs' in details.data:
                try:
                    num_jobs = int(details.data['num_jobs'])
                    job_size = int(details.data['job_size'])
                    createJobs(num_jobs, job_size)
                except:
                    raise
                    context['error'] = 'Please enter number of jobs and job size'
                    # raise
            showqueue(request, context)
            return render(request, 'merritt_index.html', context)
        else:
            # return render(request, 'merrit_archive.html', context)
            return render(request, "merritt_index.html", {'form': details})
    else:
        form = forms.Form(None)
        return render(request, 'merritt_index.html', context)

def showqueue(request, context):
    elapsedtime = time.time()
    jobs, stats, job_types, job_counts = getJoblist(request)
    context['jobs'] = jobs
    context['stats'] = stats
    context['jobcount'] = len(jobs)
    context['counts_by_type'] = job_counts
    # context['statuses'] = job_types
    context['statuses'] = JOB_STATUSES
    context['elapsedtime'] = time.time() - elapsedtime
    return context

@login_required()
def startjob(request, filename):
    elapsedtime = time.time()
    try:
        (jobnumber, step, csv ) = filename.split('.')
        loginfo('merritt_archive', '%s :: %s' % ('merritt_archive online job submission requested', filename), {}, {})
        #runjob(jobnumber, context, request)
        # give the job a chance to start to ensure the queue listing is updated properly.
        time.sleep(1)
    except:
        loginfo('merritt_archive', '%s :: %s' % ('ERROR: merritt_archive tried and failed to start job', filename), {}, {})
    return redirect('..')


    jobs, stats, job_types, job_counts = getJoblist(request, 'ready')
    context['jobs'] = jobs
    context['stats'] = stats
    context['jobmessage'] = 'jobs started'
    elapsedtime = time.time() - elapsedtime
    return context

def getJoblist(request, job_filter=None):

    if 'num2display' in request.GET:
        num2display = int(request.GET['num2display'])
    else:
        num2display = 2000

    filelist = [f for f in listdir(JOB_DIR) if isfile(path.join(JOB_DIR, f)) and ('.csv' in f)]
    jobdict = {}
    for f in sorted(filelist, reverse=True):
        if len(jobdict.keys()) > num2display:
            pass
            imagefilenames = []
        else:
            # we only need to count lines if the file is within range...
            linecount = checkFile(path.join(JOB_DIR, f))
        parts = f.split('.')
        status = parts[1]
        jobkey = parts[0]
        if not jobkey in jobdict: jobdict[jobkey] = {}
        jobdict[jobkey][status] = (f, linecount)
        # check if there is a log file for this job
        if os.path.isfile(f'{JOB_DIR}/{jobkey}.log'):
            jobdict[jobkey]['log'] = (f'{jobkey}.log', 0)
    stats = {'ready': 0, 'in progress': 0, 'running': 0, 'done': 0, 'total images': 0, 'jobs': 0}
    joblist = [(jobkey, determine_status(jobdict[jobkey]), jobdict[jobkey]) for jobkey in sorted(jobdict.keys(), reverse = True)]
    # filter unwanted jobs if asked
    if job_filter:
        for i,j in enumerate(joblist):
            if j[1] != job_filter:
                del joblist[i]
    # first, make a list of all the types of job files
    job_file_counts = defaultdict(int)
    for i,job in enumerate(joblist):
        for j in job[2]:
            job_file_counts[j] += job[2][j][1]
    job_file_types = job_file_counts.keys()
    for i, job in enumerate(joblist):
        stats['jobs'] += 1

    return joblist, stats, job_file_types, job_file_counts

def determine_status(jobdict):
    job_status = 'done'
    for j in jobdict:
        if j == 'completed':
            job_status = 'done'
            break
        elif j == 'inprogress':
            job_status = 'running'
            break
    if j == 'input' and len(jobdict) == 1:
            job_status = 'ready'
    return job_status

def checkFile(filename):
    file_handle = open(filename, encoding='utf-8')
    # eliminate rows for which an object was not found...
    lines = [l for l in file_handle.read().splitlines() if "not found" not in l]
    return len(lines)

def createJobs(num_jobs, job_size):
    images = Transaction.objects.filter(status="new").using('merritt_archive')
    #images = Transaction.objects.filter()
    jobnumber = time.strftime("%Y-%m-%d-%H-%M-%S", time.localtime())
    for n in range(num_jobs):
        job_name = f"{jobnumber}_{n:02d}.input.csv"
        jf = open(path.join(JOB_DIR, job_name), 'w', encoding='utf-8')
        n = 0
        for s in images:
            # skip images that are already queued
            check_queued = Transaction.objects.filter(status="queued", image_filename=s.image_filename)
            if check_queued: continue
            n += 1
            if n > job_size: break
            image = f'{s.transaction_detail}\n'
            jf.writelines(image)
            add_transaction(s,'queued')
        jf.close

def add_transaction(s, new_status):
    try:
        # job
        # transaction_date
        transaction = Transaction(status=new_status,
                        accession_number = s.accession_number,
                        transaction_date = s.transaction_date,
                        transaction_detail = s.transaction_detail,
                        image_filename = s.image_filename)
        save_db(transaction)
    except:
        raise

def show_archive_results(request, context):
    context['display'] = 'jobinfo'
    job = request.GET['filename']
    jobfile = path.join(JOB_DIR, job)
    elapsedtime = time.time()
    try:
        status = request.GET['status']
    except:
        status = 'showfile'
    context['filename'] = request.GET['filename']
    context['jobstatus'] = status
    f = open(jobfile, 'r', encoding='utf-8')
    filecontent = f.read()
    if status == 'showmedia':
        context['derivativegrid'] = 'Medium'
        context['sizegrid'] = '240px'
        context['imageserver'] = prmz.IMAGESERVER
        context['items'] = rendermedia(filecontent)
    elif status == 'showinportal':
        pass
    else:
        context['filecontent'] = reformat(filecontent)
    context['elapsedtime'] = time.time() - elapsedtime

    return render(request, 'uploadmedia.html', context)

def find_transactions(request, context):
    accession_number = request.POST['accession_number']
    elapsedtime = time.time()
    try:
        transactions = Transaction.objects.filter(accession_number=accession_number).using('merritt_archive').order_by('-transaction_date')[:100]
        n = len(transactions)
        context['transactions'] = transactions
    except:
        context['error'] = f'{accession_number} generated an error'
    context['elapsedtime'] = time.time() - elapsedtime

    return
