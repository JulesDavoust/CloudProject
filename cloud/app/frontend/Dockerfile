FROM node:18
WORKDIR /app
COPY . .
RUN npm install && npm run build
EXPOSE 80
CMD ["npx", "serve", "-s", "dist", "-l", "80"]
