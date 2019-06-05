kubectl delete statefulset mgpod

kubectl delete svc mongo-statefulset

kubectl delete pvc -l role=mongo

gcloud container clusters delete "alpha-cluster-1" --zone asia-east1-a