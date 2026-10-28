#!/usr/bin/env bash
# Aplica las cabeceras de seguridad de nginx del Reto 1. Ejecútalo desde la raíz del repo, en una rama nueva.
set -euo pipefail
cd "$(dirname "$0")"
cp web/nginx.conf.r1 ../web/nginx.conf
echo "copiado: web/nginx.conf. Ahora: git rm -r lab4-r1-zap  (ya no hace falta) y haz commit."