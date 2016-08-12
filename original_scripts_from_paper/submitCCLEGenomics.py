#!/usr/bin/env python
import os, sys

paths = []

with open(sys.argv[1], 'r') as x:
    for line in x:
        line = line.strip()
        line = line.split()
        if len(line) > 0:
            line[0] = float(line[0])
            paths.append(line)


paths.sort(key=lambda path: path[0])
paths.reverse()
for path in paths:
    index = 0;
    for x in range(len(path[3])):
        if path[3][x] == '/':
            index = x
    filePath = path[3][0:index+1]
    id = path[3][index+1:-4]
    print path[3], id


    os.system("""isb-cgc-pipelines submit --pipelineName your-pipeline-name \
                --inputs "%s:/working/,gs://path-to-your-kallisto-index:/working/" \
                --outputs "/working/*.tar.gz:gs://your-output-bucket/%s/" \
                --cmd "process %s" \
                --imageName "your-docker-image" \
                --cores 16 --mem 104 \
                --diskSize 350 \
                --diskType "PERSISTENT_HDD" \
                --logsPath "gs://your-output-bucket/%s/" \
                --preemptible"""% (path[3], id, id, id))
