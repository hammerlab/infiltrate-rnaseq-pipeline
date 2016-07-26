#!/usr/bin/env python
import os, sys

paths = []

with open(sys.argv[1], 'r') as x:
    for line in x:
        line = line.strip()
        line = line.split()
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
    print filePath,id
    outFile = open(id.replace('.','-').replace("_","-").replace(",","")+'.yaml','w')
    with open('template.yaml', 'r') as template:
        for line in template:
            line = line.replace('id_dashes',id.replace('.','-').replace('_','-').replace(",","").lower())
            line = line.replace('id',id)
            line = line.replace('test-disk',id.replace('.','-').replace('_','-').replace(",","").lower()+'-disk')
            line = line.replace('path',filePath)
            outFile.write(line)

    outFile.close()

    os.system('gcloud compute --project "cgc-05-0002" disks create "'+id.replace('.','-').replace('_','-').replace(",","").lower()+'-disk" --size "300" --zone "us-central1-c" --type "pd-standard" &&  kubectl create -f ./'+id.replace('.','-').replace('_','-').replace(",","")+'.yaml && rm ' + id.replace('.','-').replace('_','-').replace(",","")+ '.yaml')
