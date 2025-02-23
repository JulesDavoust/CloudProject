# Utilisation de l'image officielle MySQL 8
FROM mysql:8

# Copie du fichier de script SQL dans le répertoire d'initialisation de MySQL
COPY init.sql /docker-entrypoint-initdb.d/

# Exposition du port 3306 pour MySQL
EXPOSE 3306
