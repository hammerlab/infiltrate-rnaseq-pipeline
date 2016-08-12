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
                --inputs "%s:/working/,gs://mz-hammerlab/index/Homo_sapiens.GRCh38.cdna.all.fa.gz:/working/" \
                --outputs "/working/*.tar.gz:gs://mz-hammerlab/output/%s/" \
                --cmd "process %s" \
                --imageName "your-docker-image" \
                --cores 16 --mem 104 \
                --diskSize 350 \
                --diskType "PERSISTENT_HDD" \
                --logsPath "gs://your-output-bucket/%s/" \
                --preemptible"""% (path[3], id, id, id))




isb-cgc-pipelines submit --pipelineName test-pipeline \
                --inputs "gs://mz-hammerlab/data/ERR431606_1.fastq.gz:/working/,gs://mz-hammerlab/data/ERR431606_2.fastq.gz:/working/,gs://mz-hammerlab/index/b37.kallisto.idx:/working/" \
                --outputs "/working/*.tar.gz:gs://mz-hammerlab/output/ERR431606/" \
                --cmd "process b37.kallisto.idx ERR431606" \
                --imageName "gcr.io/pici-1286/mz-rna-pipeline" \
                --cores 16 --mem 104 \
                --diskSize 350 \
                --diskType "PERSISTENT_HDD" \
                --logsPath "gs://mz-hammerlab/output/ERR431606/"


                 \
                --preemptible



change process to take:
1. input filename
2. output filename


run this on:
gcloud compute instances create mz-pipeline-workstation --metadata startup-script-url=gs://isb-cgc-open/vm-startup-scripts/isb-cgc-pipelines-startup.sh --scopes cloud-platform





gcloud container --project "pici-1286" clusters create "some-cluster" \
    --zone "us-east1-b" --machine-type "n1-highmem-4" \
    --scope "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write","https://www.googleapis.com/auth/taskqueue","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management" \
    --num-nodes "3" --network "default" --enable-cloud-logging --no-enable-cloud-monitoring;
gcloud compute --project "pici-1286" disks create "some-disk" --size "300" --zone "us-east1-b" --type "pd-standard"
kubectl create -f ./some-task.yaml # all ids must be lowercase
kubectl get pods
kubectl cluster-info
kubectl config view
