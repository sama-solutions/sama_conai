# Dockerfile pour l'application mobile web SAMA CONAI
FROM node:18-alpine

# Métadonnées
LABEL maintainer="SAMA CONAI Team"
LABEL description="Application mobile web pour la plateforme de transparence SAMA CONAI"
LABEL version="1.0.0"

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3001

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production && npm cache clean --force

# Copier le code source
COPY . .

# Changer la propriété des fichiers
RUN chown -R nextjs:nodejs /app

# Créer le répertoire des logs
RUN mkdir -p /app/logs && chown -R nextjs:nodejs /app/logs

# Passer à l'utilisateur non-root
USER nextjs

# Exposer le port
EXPOSE 3001

# Vérification de santé
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1

# Commande de démarrage
CMD ["npm", "start"]