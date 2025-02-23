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
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
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

# 📦 Installation de Ingress Controller si non présent
if ! kubectl get ns ingress-nginx &>/dev/null; then
  echo -e "${GREEN}➡️ Installation de Nginx Ingress Controller...${NC}"
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
  sleep 10
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
else
  echo -e "${GREEN}✅ Nginx Ingress est déjà installé.${NC}"
fi

# 🔄 Création du namespace dev
kubectl create ns dev --dry-run=client -o yaml | kubectl apply -f -

# 🏗️ Build & Push des images Docker
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

# 🚀 Déploiement des services Kubernetes
echo -e "${GREEN}➡️ Déploiement des services Kubernetes...${NC}"

kubectl apply -f k8s/backend-deployment-temp.yml -n dev
kubectl apply -f k8s/frontend-deployment-temp.yml -n dev
kubectl apply -f k8s/mysql-deployment-temp.yml -n dev

# 🛑 Suppression de l'Ingress existant s'il y en a un
echo -e "${GREEN}➡️ Suppression de l'Ingress existant (si présent)...${NC}"
kubectl delete ingress app-ingress -n dev --ignore-not-found=true

# ⏳ Attente pour éviter les conflits
sleep 10

# 🚀 Appliquer le nouvel Ingress
kubectl apply -f k8s/ingress.yml -n dev

# 🔄 Attente de la disponibilité des pods
echo -e "${GREEN}⌛ Attente de la disponibilité des pods...${NC}"
kubectl wait --for=condition=ready pod --all -n dev --timeout=180s

# 🎯 Vérification des services et Ingress
kubectl get svc -n dev
kubectl get ingress -n dev

# 🏁 Message de fin
echo -e "${GREEN}🎉 Déploiement terminé ! Accédez à votre application via : http://myapp.local${NC}"
