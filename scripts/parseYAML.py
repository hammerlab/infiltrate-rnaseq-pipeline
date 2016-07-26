#!/usr/bin/env python
import sys, re, subprocess, pickle
from yaml import load
id_regex = re.compile(r'gs\:\/\/your-output-bucket\/(.+)\/')
output_regex = re.compile(r'gs\:\/\/your-output-bucket/.+')
jobs = []

with open(sys.argv[1], 'r') as jobs_file:
   cur_yaml = ""
   for line in jobs_file:
       if line == "---\n":
           if len(cur_yaml) > 0:
               job = load(cur_yaml)
               # print job['metadata']['request']['pipelineArgs']['outputs']['output0']
               if output_regex.search(job['metadata']['request']['pipelineArgs']['outputs']['output0']):
                   if "error" not in job.keys() or job['error']['code'] == 10:
                       jobs.append(job)

           cur_yaml = ""
       else:
           cur_yaml += line



print "Sample\tEvent\tTime\tGoogle ID"
i = 0
for job in jobs:
    i += 1
    print >> sys.stderr, "Processing job #%d" % i
    match = id_regex.match(job['metadata']['request']['pipelineArgs']['logging']['gcsPath'])
    _id = match.group(1)
    google_id = job['name'].replace('operations/','')

    print "\t".join([_id, "creation", job['metadata']['createTime'].replace("T",' ').replace("Z",''), google_id])

    if "error" in job.keys():
        print "\t".join([_id, "preempted", job['metadata']['endTime'].replace("T",' ').replace("Z",''), google_id])
    else:
        print "\t".join([_id, "finished", job['metadata']['endTime'].replace("T",' ').replace("Z",''), google_id])
    for event in job['metadata']['events']:
        print "\t".join([_id, event['description'], event['startTime'].replace("T",' ').replace("Z",''), google_id ])
