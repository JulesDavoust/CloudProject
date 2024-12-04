# Étape 1 : Construction du frontend
FROM node:20.11.0 AS builder
WORKDIR /app
COPY package.json package-lock.json ./
USER root
RUN npm install
COPY . .
RUN npm run build

# Étape 2 : Image finale pour servir les fichiers statiques
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]