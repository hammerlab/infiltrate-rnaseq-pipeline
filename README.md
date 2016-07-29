# rnaseq-pipeline


launch single-node-nfs: https://cloud.google.com/launcher/solution/click-to-deploy-images/singlefs
called it mz-nfs-vm

to monitor: (see https://console.cloud.google.com/deployments/details/mz-nfs?src=launcher&project=pici-1286)
`gcloud compute ssh --ssh-flag=-L3000:localhost:3000 --project=pici-1286 --zone us-east1-b mz-nfs-vm`
go to http://localhost:3000/
login with admin / X*QZcMsf3Y29nS
if you ssh in, the data is at `/mz-data`

from a GCE VM (`ssh -A maximz.us-east1-b.pici-1286`):
```
sudo apt-get install nfs-common
sudo mkdir /mnt/mz-data
sudo chmod a+w /mnt/mz-data
echo 'mz-nfs-vm:/mz-data /mnt/mz-data nfs rw 0 0' | sudo tee -a /etc/fstab
sudo mount -t nfs mz-nfs-vm:/mz-data /mnt/mz-data
```

used that to add an index.html.

from Kube (`nfs/``):
```
gcloud container clusters get-credentials some-cluster
#kubectl create -f test.yaml # ignore does not work
kubectl create -f nfs-pv.yaml # persistent volume
kubectl create -f nfs-pvc.yaml # persistent volume claim
# run web server
kubectl create -f nfs-web-rc.yaml # makes two pods, serving index.html from 
kubectl create -f nfs-web-service.yaml # makes service to front the two pods
# test it
kubectl get services nfs-web # get ip, put its ip below
kubectl get pods # get any pod, put its name below
#kubectl exec nfs-web-t7uvx -- wget -qO- http://10.87.252.1
kubectl exec nfs-web-t7uvx bash
> apt-get update
> apt-get install -y wget
> wget http://10.87.252.1
> cat index.html
> # test whether can write to nfs from container
> cd /usr/share/nginx/html/
> echo 'test' > anothertest
> cat anothertest
```



# building the docker image

```
git clone git@github.com:maximz/rnaseq-pipeline.git
./build.sh
./run.sh
docker tag maximz/rnapipeline gcr.io/pici-1286/mz-rna-pipeline
gcloud docker push gcr.io/pici-1286/mz-rna-pipeline
```

(i ran this from maximz gcloud vm)


# launch kube tasks

```
gcloud container --project "pici-1286" clusters create "some-cluster" \
    --zone "us-east1-b" --machine-type "n1-highmem-4" \
    --scope "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write","https://www.googleapis.com/auth/taskqueue","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management" \
    --num-nodes "3" --network "default" --enable-cloud-logging --no-enable-cloud-monitoring;
gcloud compute --project "pici-1286" disks create "some-disk" --size "300" --zone "us-east1-b" --type "pd-standard"
kubectl create -f ./some-task.yaml # all ids must be lowercase. # this didn't work
kubectl get pods
kubectl cluster-info
kubectl config view

# load web UI from there
chrome https://104.196.139.139/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard


# clean up
kubectl get jobs
kubectl delete jobs --all

# new
kubectl create -f ./nfsFullTest.yaml
# monitor
kubectl get jobs
kubectl describe jobs/process-err431606
# notice that job was successful in 3 seconds, wow
# check from somewhere else that has access to nfs whether the file anewfile was created -- it was!!!

# clean up
kubectl delete jobs --all

# real
# if instant "successful", then something went wrong. unclear why returning "successful" -- maybe need to add "stop on error" to bash. one way to get it to fail is to do volumeMount to /data instead of to /working.
kubectl create -f ./real.yaml


# make sure failures are caught properly -- they are!
kubectl create -f ./brokenExample.yaml # will not work, deliberately! 
kubectl describe jobs/process-err431606 # monitor this
# seems to produce unlimited failures. unclear how to limit the number of restarts.... documented here: https://github.com/kubernetes/kubernetes/issues/24533
kubectl delete jobs --all # clean up. may seem like it fails at first, but just keep rerunning. https://github.com/kubernetes/kubernetes/issues/25704
```


# resize

Stop the VM to resize. (Did we have to stop the cluster???)

cluster --> from 3 nodes to 5 nodes
nfs mz-nfs-vm --> from 2 vCPU, 7.5GB RAM to 8 vCPU, 40 GB RAM

Filter Instances by `name:gke-some-cluster-*` to see the 5 cluster nodes. 

# launch data downloads

go to `get_data/`.

```
# ran these on maximz box
./build.sh
./test.sh
./publish_image.sh

# ran these from local
rm jobs/*
python make_jobs.py
kubectl create -f ./jobs
kubectl get jobs | wc -l # should be 127, subtract one for 126
wc -l list_of_data.txt # should be 125, but do not have line break at end so actually 126
```

## monitor this while it happens

Looks like it runs 15 pods at a time. (15 tasks)

* http://localhost:3000/dashboard/db/storage
* http://localhost:3000/dashboard/db/system
* https://104.196.139.139/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard

It worked well -- only one job failed, rescheduled (new pod), succeeded.
Only issue is that logs are no longer available in Kubernetes -- I guess the pods get garbage collected. This is a known issue:

```
kubectl get pods -a
> ...
> download-err431623-2-52tlr   0/1       Completed   0          1h
> download-err431623-2-rds71   0/1       Error       0          2h
> ...
kubectl logs download-err431623-2-52tlr --previous
> Error from server: previous terminated container "download-err431623-2" in pod "download-err431623-2-52tlr" not found
kubectl logs download-err431623-2-rds71 --previous
> Error from server: previous terminated container "download-err431623-2" in pod "download-err431623-2-rds71" not found

```

# run the process tasks

go to `image/`

```
# ran these on maximz box
./build.sh
./test.sh
./publish_image.sh

# ran these from local
rm jobs/*
python make_jobs.py
kubectl create -f ./jobs
kubectl get jobs | grep 'process' | wc -l # should be 126. all the download jobs are still in there as completed. ACTUALLY SHOULD BE 126/2 = 63.
wc -l ../list_of_data.txt # should be 125, but do not have line break at end so actually 126
```

Oops I screwed up, sent full file name instead of prefix:
logs say `2016-07-28T21:07:14.042061665Z unpigz: ERR431566_1.fastq.gz*.fastq.gz does not exist -- skipping`
I saw this at dashboard at https://104.196.139.139/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/log/default/process-err431566-1-zjswo/

So delete all jobs and start again: `kubectl delete jobs --all`, `kubectl get jobs` to verify, then redo above.

Note that this took forever -- see my Twitter thread here: https://twitter.com/zazius/status/758816688171126784

Rewrote jobs and launched as above. should have 63 jobs now. :)

# Weird NFS bug

Experienced a very weird nfs bug where i can no longer write and files are owned by googlers' usernames. see `gce bug` for the details.

Tried many things, posted on Twitter, etc.
But gave up eventually.

Launched mz-nfs-2 and going to redo all of the above.

```
### MAKE SURE NEW NFS WORKS PROPERLY (have to wait a few mins for initialization though)
# From maximz VM:
sudo umount /mnt/mz-data
sudo mount -t nfs mz-nfs-2-vm:/mz-data /mnt/mz-data
# edit /etc/fstab


### SSH to NFS
gcloud compute ssh --ssh-flag=-L3000:localhost:3000 --project=pici-1286 --zone us-east1-b mz-nfs-2-vm
# go to localhost:3000: admin / m1VwMwEbTu84+3

## set up kubernetes volume
gcloud container clusters get-credentials some-cluster
kubectl delete pv,pvc --all
kubectl get pv
kubectl get pvc
kubectl create -f nfs/nfs-pv.yaml # persistent volume
kubectl create -f nfs/nfs-pvc.yaml # persistent volume claim

# load web UI from there
chrome https://104.196.139.139/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard


### launch download jobs

# cd get_data
# rm jobs/*
# python make_jobs.py
# kubectl create -f ./jobs
# kubectl get jobs | wc -l
```

NO fixed the NFS bug like this:

```
maxim@mz-nfs-vm:/mz-data$ sudo chmod -R 777 *
```

BUT have to redo the pv,pvc because I had deleted them
```
kubectl delete pv,pvc --all
kubectl get pv
kubectl get pvc
kubectl create -f nfs/nfs-pv.yaml # persistent volume -- make sure vm set properly here
kubectl create -f nfs/nfs-pvc.yaml # persistent volume claim
```

Test it out:
```
kubectl create -f nfs/nfsFullTest.yaml
kubectl create -f nfs/nfsFullTest2.yaml
kubectl get jobs
kubectl delete jobs --all
```

Built new image because updated customProcess.sh.

Rerun jobs:
```
rm jobs/*
python make_jobs.py
kubectl create -f ./jobs
kubectl get jobs | grep 'process' | wc -l # should be 63
```

Things are running happily.

Turn down and delete mz-nfs-2, and its disk.
