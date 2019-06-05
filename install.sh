gcloud config set compute/zone asia-east1-a

gcloud container clusters create alpha-cluster-1 \
   --zone "asia-east1-a" \
   --username "admin" \
   --machine-type "n1-standard-1" \
   --disk-type "pd-ssd" \
   --disk-size "30" \
   --num-nodes "3" \
   --enable-cloud-logging \
   --enable-cloud-monitoring \
#   --network "default" \
   --no-enable-autoupgrade \
   --no-issue-client-certificate \
   --metadata disable-legacy-endpoints=true \
   --addons HorizontalPodAutoscaling,HttpLoadBalancing,KubernetesDashboard

gcloud container clusters get-credentials alpha-cluster-1 --zone asia-east1-a

kubectl apply -f gcp_ssd.yaml

gcloud compute firewall-rules create \
  allow-27017-fwr --target-tags allow-27017 --allow tcp:27017 \
  --network default --source-ranges 10.140.0.0/24

gcloud container clusters describe alpha-cluster-1 --format=get"(allow-27017-fwr)" --zone asia-east1-a

gcloud compute disks list

touch internal-keyfile

/usr/bin/openssl rand -base64 741 > internal-keyfile

cat internal-keyfile

kubectl create secret generic shared-bootstrap-data --from-file='internal-keyfile'

rm internal-keyfile

kubectl apply -f mongo-statefulset.yaml

kubectl get statefulset

echo "Creating Pods"

sleep 180s

kubectl get pods

kubectl exec -ti mgpod-0 bash
