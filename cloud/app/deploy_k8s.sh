#!/bin/bash

# 🛑 Arrêter le script en cas d'erreur
set -e

# 🎨 Couleurs pour les logs
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 🔍 Vérification des outils nécessaires
echo -e "${GREEN}➡️ Vérification des outils nécessaires...${NC}"

check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "${RED}❌ $1 n'est pas installé !${NC}"
    exit 1
  else
    echo -e "${GREEN}✅ $1 est installé.${NC}"
  fi
}

check_command "docker"
check_command "kubectl"
check_command "minikube"
check_command "sed"

# 🚀 Demander les identifiants Docker
echo -e "${GREEN}➡️ Connexion à Docker Hub...${NC}"
read -p "Entrez votre username Docker Hub : " DOCKER_USERNAME
read -s -p "Entrez votre token Docker Hub (mot de passe) : " DOCKER_PASSWORD
echo

# 🔐 Connexion à Docker Hub
export DOCKER_CONTENT_TRUST=1
docker login -u "$DOCKER_USERNAME" --password-stdin <<< "$DOCKER_PASSWORD"
if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Échec de connexion à Docker Hub !${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Connexion réussie à Docker Hub.${NC}"

# 🚀 Demander les noms des images Docker
echo -e "${GREEN}➡️ Configuration des noms d'images Docker...${NC}"
read -p "Nom de l'image BACKEND (ex: backend:v1) : " BACKEND_TAG
read -p "Nom de l'image FRONTEND (ex: frontend:v1) : " FRONTEND_TAG
read -p "Nom de l'image DATABASE (ex: database:v1) : " DATABASE_TAG

BACKEND_IMAGE="$DOCKER_USERNAME/$BACKEND_TAG"
FRONTEND_IMAGE="$DOCKER_USERNAME/$FRONTEND_TAG"
DATABASE_IMAGE="$DOCKER_USERNAME/$DATABASE_TAG"

# 🚀 Lancer Minikube si ce n’est pas déjà fait
echo -e "${GREEN}➡️ Démarrage de Minikube...${NC}"
if ! minikube status &>/dev/null; then
  minikube start --driver=docker --cpus=4 --memory=6g
else
  echo -e "${GREEN}✅ Minikube est déjà en cours d'exécution.${NC}"
fi

# 🏗️ Configurer le registre Docker local
eval $(minikube docker-env)

# 📦 Demander le type de déploiement (Ingress ou Istio)
echo -e "${GREEN}➡️ Choisissez le mode de déploiement :${NC}"
select DEPLOYMENT_MODE in "Ingress" "Istio"; do
  case $DEPLOYMENT_MODE in
    Ingress ) echo -e "${GREEN}📌 Mode sélectionné : Ingress${NC}"; break;;
    Istio ) echo -e "${GREEN}📌 Mode sélectionné : Istio${NC}"; break;;
    * ) echo -e "${RED}Option invalide. Veuillez choisir Ingress ou Istio.${NC}";;
  esac
done

# 🔥 Suppression propre de l'ancien mode
if [ "$DEPLOYMENT_MODE" == "Ingress" ]; then
  echo -e "${GREEN}➡️ Suppression des configurations Istio...${NC}"
  kubectl delete gateway myapp-gateway -n dev --ignore-not-found=true
  kubectl delete virtualservice myapp-virtualservice -n dev --ignore-not-found=true
  kubectl delete peerauthentication default -n dev --ignore-not-found=true
  kubectl delete namespace istio-system --ignore-not-found=true
  kubectl label namespace dev istio-injection- --overwrite
  echo -e "${GREEN}✅ Istio complètement supprimé.${NC}"
fi

if [ "$DEPLOYMENT_MODE" == "Istio" ]; then
  echo -e "${GREEN}➡️ Suppression des configurations Ingress...${NC}"
  kubectl delete ingress app-ingress -n dev --ignore-not-found=true
  kubectl delete namespace ingress-nginx --ignore-not-found=true
  echo -e "${GREEN}✅ Ingress complètement supprimé.${NC}"
fi

# 🔄 Redémarrer les pods pour éviter les conflits
echo -e "${GREEN}➡️ Redémarrage des pods pour appliquer la configuration proprement...${NC}"
kubectl delete pod --all -n dev --ignore-not-found=true
sleep 10

# 📦 Installation de Ingress ou Istio
if [ "$DEPLOYMENT_MODE" == "Ingress" ]; then
  echo -e "${GREEN}➡️ Installation de Nginx Ingress Controller...${NC}"
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
  sleep 10
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
fi

if [ "$DEPLOYMENT_MODE" == "Istio" ]; then
  echo -e "${GREEN}➡️ Installation d'Istio...${NC}"
  istioctl install --set profile=demo -y
  kubectl label namespace dev istio-injection=enabled --overwrite
  sleep 10
fi

# 🔄 Création du namespace dev
kubectl create ns dev --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}➡️ Construction et push des images Docker...${NC}"
docker build -t $BACKEND_IMAGE ./backend
docker build -t $FRONTEND_IMAGE ./frontend
docker build -t $DATABASE_IMAGE ./database

docker push $BACKEND_IMAGE
docker push $FRONTEND_IMAGE
docker push $DATABASE_IMAGE

# 🔄 Mise à jour des fichiers YAML avec les nouvelles images
echo -e "${GREEN}➡️ Mise à jour des fichiers YAML avec les nouvelles images...${NC}"
sed "s|image: .*api.*|image: $BACKEND_IMAGE|g" k8s/backend-deployment.yml > k8s/backend-deployment-temp.yml
sed "s|image: .*frontend.*|image: $FRONTEND_IMAGE|g" k8s/frontend-deployment.yml > k8s/frontend-deployment-temp.yml
sed "s|image: .*database.*|image: $DATABASE_IMAGE|g" k8s/mysql-deployment.yml > k8s/mysql-deployment-temp.yml

# 🔄 Application des ressources de sécurité
kubectl apply -f k8s/backend-sa.yml -n dev
kubectl apply -f k8s/backend-role.yml -n dev
kubectl apply -f k8s/backend-rolebinding.yml -n dev

if [ "$DEPLOYMENT_MODE" == "Istio" ]; then
  kubectl apply -f k8s/peer-authentication.yml -n dev
fi

# 🚀 Déploiement des services Kubernetes
echo -e "${GREEN}➡️ Déploiement des services Kubernetes...${NC}"
kubectl apply -f k8s/backend-deployment-temp.yml -n dev
kubectl apply -f k8s/frontend-deployment-temp.yml -n dev
kubectl apply -f k8s/mysql-deployment-temp.yml -n dev

# 🔄 Appliquer Ingress ou Istio
if [ "$DEPLOYMENT_MODE" == "Ingress" ]; then
  kubectl apply -f k8s/ingress.yml -n dev
elif [ "$DEPLOYMENT_MODE" == "Istio" ]; then
  kubectl apply -f k8s/istio-gateway.yml -n dev
  kubectl apply -f k8s/istio-virtualservices.yml -n dev
fi

if [[ "$DEPLOYMENT_MODE" == "Istio" ]]; then
  echo -e "${GREEN}🚀 Déploiement avec Istio détecté ! Vérification des ressources Istio...${NC}"
  kubectl get gateway,virtualservice,destinationrule -n dev
  kubectl get pods,svc -n istio-system
  echo -e "${GREEN}✅ Istio est bien en place !${NC}"
elif [[ "$DEPLOYMENT_MODE" == "Ingress" ]]; then
  echo -e "${GREEN}🚀 Déploiement avec Ingress détecté ! Vérification des ressources Ingress...${NC}"
  kubectl get ingress -n dev
  kubectl get pods,svc -n ingress-nginx
  echo -e "${GREEN}✅ Ingress est bien en place !${NC}"
else
  echo -e "${RED}❌ Erreur : Aucun mode de déploiement (Istio ou Ingress) détecté !${NC}"
  exit 1
fi

# 🔎 Vérification
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get peerauthentication -n dev --ignore-not-found=true

echo -e "${GREEN}🎉 Déploiement terminé ! Accédez à votre application via : http://myapp.local${NC}"
