# api: Node.js con Express. Sigue las seis reglas del LAB-02:
# tag fijo, dependencias antes que código, sin root, sin secretos, imagen chica, un proceso.
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

# B1 (Trivy CRITICAL,HIGH): paquetes del sistema al día, sin dejar caché.
RUN apk upgrade --no-cache

COPY package*.json ./
# En producción solo se ejecuta "node": npm y corepack no hacen falta. Quitarlos elimina de la imagen
# las dependencias de npm (tar, glob, cross-spawn...) que son la fuente típica de HIGH en node:alpine.
RUN npm ci --omit=dev \
    && npm cache clean --force \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack \
              /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack

COPY app.js server.js ./

# node es el uid 1000 en la imagen oficial. Numérico para que Kubernetes pueda verificar runAsNonRoot.
USER 1000
EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-qO-", "http://127.0.0.1:3000/api/health"]

CMD ["node", "server.js"]
