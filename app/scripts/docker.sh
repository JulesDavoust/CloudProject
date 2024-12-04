#!/bin/bash
set -e

# Variables
DOCKER_USERNAME="fowx"
DOCKER_PASSWORD="dckr_pat_G4R1zoQYUVnEhBBwb2onAAYUEQU"
PROJECT_NAME="app"  # Remplacez par le nom réel de votre projet

# Connexion à Docker Hub
echo "Logging in to Docker Hub..."
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin || {
    echo "Docker login failed. Exiting script."
    exit 1
}

# Construire les images
echo "Building images with Docker Compose..."
docker-compose build || { echo "Docker Compose build failed. Exiting script."; exit 1; }

# Pousser les images vers Docker Hub
services=("frontend" "api" "database")
for service in "${services[@]}"; do
    IMAGE_TAG="${DOCKER_USERNAME}/cloudproject_${service}:latest"
    docker images
    echo "Tagging and pushing image for $service..."
    docker push "$IMAGE_TAG" || { echo "Failed to push image for $service. Exiting script."; exit 1; }
done

# Démarrer les services
echo "Starting services with Docker Compose..."
docker-compose up -d || { echo "Failed to start services. Exiting script."; exit 1; }

# Vérification des services
echo "Verifying services are running..."
docker-compose ps

echo "All services started successfully!"
