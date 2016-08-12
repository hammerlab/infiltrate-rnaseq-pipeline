#!/usr/bin/env python
import os, sys

unique_ids = []
samples = []
cancer_types = ["LUSC","BRCA"] #add cancer types to exclude
with open(sys.argv[1], 'r') as in_file:
    for line in in_file:
        line = line.strip().split(',')
        cancer_type = line[1]
        path = line[8]
        gchub_id = line[9]
        if gchub_id in unique_ids:
            print gchib_id, "NOT UNIQUE!"
            sys.exit(1)
        unique_ids.append(gchub_id)
        if cancer_type not in cancer_types:
            samples.append([path,gchub_id])

print len(samples)
i = 0
for sample in samples:
   path = sample[0]
   id = sample[1]
   os.system("""isb-cgc-pipelines submit --pipelineName your-pipeline-name\
               --inputs "%s:/working/,gs://path-to-your-kallisto-index:/working/" \
               --outputs "/working/*.tar.gz:gs://your-output-bucket/%s/" \
               --cmd "process %s" \
               --imageName "your-docker-image" \
               --cores 2 --mem 7.5 \
               --diskSize 350 \
               --diskType "PERSISTENT_HDD" \
               --logsPath "gs://your-output-bucket/%s/" \
               --preemptible"""% (path, id, id, id))
   i += 1
   print "Submitted %d of %d" % (i, len(samples))
