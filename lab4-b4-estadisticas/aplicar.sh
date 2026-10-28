#!/usr/bin/env bash
# Copia los archivos del B4 sobre su lugar en el repositorio (quita el sufijo .b4). Ejecútalo desde la raíz del repo, en una rama nueva.
# Los archivos llevan .b4 para que Vitest y ESLint no los tomen por pruebas de verdad mientras no se aplican.
set -euo pipefail
cd "$(dirname "$0")"
find . -type f -name '*.b4' | while read -r f; do
  destino="../${f#./}"; destino="${destino%.b4}"
  cp "$f" "$destino"; echo "copiado: ${destino#../}"
done
echo "Listo. Ahora: git rm -r lab4-b4-estadisticas  (ya no hace falta) y haz commit."