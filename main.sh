read -p "Do you want to start minikube ? (y/n) " startMinikube
if [ $startMinikube == "y" ]
then
    minikube stop
    minikube start --extra-config=apiserver.Authorization.Mode=RBAC
fi


read -p "Do you want to launch docker-compose ? (y/n) " startDockerCompose
if [ $startDockerCompose == "y" ]
then
    bash app/scripts/docker.sh
fi

read -p "Do you want to launch kubernetes files ? (y/n) " startKubernetes
if [ $startKubernetes == "y" ]
then
    bash app/scripts/kubernetes.sh
fi

read -p "Do you want to start minikube tunnel ? (y/n) " minikubeTunnel
if [ $minikubeTunnel == "y" ]
then
    minikube tunnel
fi

if ! kubectl api-versions | grep -q rbac.authorization.k8s.io; then
    echo "RBAC is not enabled. You have to restart your minikube, and start it with rbac"
else
    echo "RBAC is already enabled. Applying roles.yml and rolesbinding.yml..."
    kubectl apply -f app/kubernetes/roles/roles.yml
    kubectl get roles -n dev

    kubectl apply -f app/kubernetes/roles/rolesbinding.yml
    kubectl get rolebindings -n dev

    echo "Test roles..."
    bash app/scripts/role-test.sh
fi

echo "Applying security files..."
kubectl apply -f app/kubernetes/security/security-frontend-api.yml
kubectl apply -f app/kubernetes/security/deny-all.yml
kubectl apply -f app/kubernetes/security/mtls-peer-auth.yaml
kubectl apply -f app/kubernetes/security/destination-rule-db.yaml



exit 0