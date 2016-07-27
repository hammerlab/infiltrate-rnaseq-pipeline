
launch single-node-nfs: https://cloud.google.com/launcher/solution/click-to-deploy-images/singlefs
called it mz-nfs-vm

to monitor: (see https://console.cloud.google.com/deployments/details/mz-nfs?src=launcher&project=pici-1286)
`gcloud compute ssh --ssh-flag=-L3000:localhost:3000 --project=pici-1286 --zone us-east1-b mz-nfs-vm`
go to http://localhost:3000/
login with admin / X*QZcMsf3Y29nS

from a GCE VM (`ssh -A maximz.us-east1-b.pici-1286`):
```
sudo apt-get install nfs-common
sudo mkdir /mnt/mz-data
sudo chmod a+w /mnt/mz-data
echo 'mz-nfs-vm:/mz-data /mnt/mz-data nfs rw 0 0' | sudo tee -a /etc/fstab
sudo mount -t nfs mz-nfs-vm:/mz-data /mnt/mz-data
```

used that to add an index.html.

from Kube:
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
```