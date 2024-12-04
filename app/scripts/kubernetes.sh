minikube stop
minikube start

kubectl create namespace dev
kubectl config set-context --current --namespace=dev
# kubectl apply -f kubernetes/frontend/frontend-deployment.yaml
# kubectl apply -f kubernetes/frontend/frontend-loadbalancing-service.yaml
kubectl apply -f ../kubernetes/frontend/frontend-mesh.yml

# kubectl apply -f kubernetes/backend/API/API-deployment.yaml
# kubectl apply -f kubernetes/backend/API/API-loadbalancing-service.yaml
kubectl apply -f ../kubernetes/backend/API/API-mesh.yml

# kubectl apply -f kubernetes/backend/Database/mysql-secret.yaml
# kubectl apply -f kubernetes/backend/Database/mysql-storage.yaml
# kubectl apply -f kubernetes/backend/Database/mysql-deployment.yaml
# kubectl apply -f kubernetes/backend/Database/mysql-serviceClusterIp.yaml
# kubectl apply -f kubernetes/backend/Database/mysql-serviceNodePort.yaml