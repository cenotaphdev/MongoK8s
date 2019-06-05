# https://codelabs.developers.google.com/codelabs/cloud-mongodb-statefulset/index.html?index=..%2F..index#5
# https://www.youtube.com/watch?v=m8anzXcP-J8
# http://pauldone.blogspot.com/2017/06/deploying-mongodb-on-kubernetes-gke25.html

$ gcloud config set compute/zone asia-east1-a

$ gcloud container clusters create alpha-cluster-1 \
   --zone "asia-east1-a" \
   --username "admin" \
   --machine-type "n1-standard-1" \
   --disk-type "pd-ssd" \
   --disk-size "30" \
   --num-nodes "3" \
   --enable-cloud-logging \
   --enable-cloud-monitoring \
   --network "default" \
   --no-enable-autoupgrade \
   --no-issue-client-certificate \
   --metadata disable-legacy-endpoints=true \
   --addons HorizontalPodAutoscaling,HttpLoadBalancing,KubernetesDashboard

# --metadata disable-legacy-endpoints=true

$ gcloud container clusters get-credentials alpha-cluster-1 --zone asia-east1-a

$ kubectl apply -f gcp_ssd.yaml

# OR $ kubectl apply -f gcp_hdd.yaml for standard harddisk

$ gcloud compute firewall-rules create \
  allow-27017-fwr --target-tags allow-27017 --allow tcp:27017 \
  --network default --source-ranges 10.140.0.0/24

$ gcloud container clusters describe alpha-cluster-1 --format=get"(allow-27017-fwr)" --zone asia-east1-a

$ gcloud container clusters list

# $ gcloud compute disks create pd-ssd-disk-1 pd-ssd-disk-2 pd-ssd-disk-3 --size 30GB --type pd-ssd --zone us-east1-a

$ gcloud compute disks list

This will show that the state of each volume is marked as “available” (i.e. no container has staked a claim on each yet).

A key deviation from the original Google blog post, is enabling MongoDB authentication immediately, before any "mongod" processes are started. Enabling authentication for a MongoDB replica set doesn’t just enforce authentication of applications using MongoDB, but also enforces internal authentication for inter-replica communication. Therefore, lets generate a keyfile to be used for internal cluster authentication and register it as a Kubernetes Secret:

$ touch internal-auth-mongodb-keyfile
$ /usr/bin/openssl rand -base64 741 > internal-auth-mongodb-keyfile
$ cat internal-auth-mongodb-keyfile
$ kubectl create secret generic shared-bootstrap-data --from-file='internal-auth-mongodb-keyfile'

----------------------------------------------------------------------------------------------------------------

// This step you will need create kubernetes cluster name is 'alpha-cluster-1' with kubernetes engine
// Please add location zone in 'asia-east1-a'


$ kubectl apply -f mongo-statefulset.yaml

$ kubectl get statefulset

$ kubectl get pods

$ kubectl exec -ti mgpod-0 bash

$ ps -aux
$ hostname -f

# Result : mgpod-0.mongo-statefulset.default.svc.cluster.local

$ mongo

>rs.initiate( {_id: "MainRepSet", version: 1, members: [
      { _id: 0, host: "mgpod-0.mongo-statefulset.default.svc.cluster.local:27017" },
      { _id: 1, host: "mgpod-1.mongo-statefulset.default.svc.cluster.local:27017" },
      { _id: 2, host: "mgpod-2.mongo-statefulset.default.svc.cluster.local:27017" }
 ]});

>rs.status();

> db.getSiblingDB("admin").createUser({
      user : "cenotaphadmin",
      pwd  : "nongnae1234",
      roles: [ { role: "root", db: "admin" } ]
 });

 # Test
Run Some Quick Tests
Let just prove a couple of things before we finish:

1. Show that data is indeed being replicated between members of the containerised replica set.
2. Show that even if we remove the replica set containers and then re-create them, the same stable hostnames are still used and no data loss occurs, when the replica set comes back online. The StatefulSet’s Persistent Volume Claims should successfully result in the same storage, containing the MongoDB data files, being attached to by the same “mongod” container instance identities.

Whilst still in the Mongo Shell from the previous step, authenticate and quickly add some test data:

> db.getSiblingDB('admin').auth("cenotaphadmin", "nongnae1234");
> use test;
> db.testcoll.insert({a:1});
> db.testcoll.insert({b:2});
> db.testcoll.find();


Exit out of the shell and exit out of the first container (“mongod-0”). Then using the following commands, connect to the second container (“mongod-1”), run the Mongo Shell again and see if the data we’d entered via the first replica, is visible to the second replica:

$ kubectl exec -ti mgpod-1 bash
$ mongo
> db.getSiblingDB('admin').auth("cenotaphadmin", "nongnae1234");
> db.setSlaveOk(1); 
rs.slaveOk()
> use test;
> db.testcoll.find();

You should see that the two records inserted via the first replica, are visible to the second replica.

To see if Persistent Volume Claims really are working, use the following commands to drop the Service & StatefulSet (thus stopping the pods and their “mongod” containers) and re-create them again (I’ve included some checks in-between, so you can track the status):

$ kubectl delete statefulsets mgpod
$ kubectl delete svc mongo-statefulset
$ kubectl get all
$ kubectl get persistentvolumes
$ kubectl apply -f mongodb-service.yaml
$ kubectl get all

# Scale 

kubectl scale --replicas=5 statefulset mgpod

"mongodb://myDBReader:D1fficultP%40ssw0rd@mongodb0.example.com:27017,mongodb1.example.com:27017,mongodb2.example.com:27017/admin?replicaSet=myRepl"

# Delete
kubectl delete statefulset mgpod
kubectl delete svc mongo-statefulset
kubectl delete pvc -l role=mongo
gcloud container clusters delete "alpha-cluster-1"


