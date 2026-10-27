# Pasos para terminar el LAB-04 con este código

> Importante: nada de esto se ejecutó todavía (no hay Node, Docker ni acceso a GitHub donde se preparó). El código está revisado a mano, no probado. El primer run en GitHub puede pedir ajustes pequeños; en cada paso dice qué mirar.

## 0. Qué cambia respecto a tu LAB-03

Nada de tu LAB-03 hay que corregirlo para que funcione el LAB-04: son **repositorios distintos**. El LAB-03 es `KrisD08.github.io` (tu perfil). El LAB-04 se hace en **`demo-cicd`**, que sale de la plantilla del profesor. Lo que sí se reutilizó de tu LAB-03: los SHA fijados de las acciones, los scripts de resumen (`resumen-vitest`, `resumen-trivy`), `concurrency`, `timeout-minutes` y `persist-credentials: false`.

Una diferencia que conviene saber: en el LAB-03 calculabas el dueño en minúsculas con `${DUENO,,}`. Aquí se usa `tr '[:upper:]' '[:lower:]'` (como pide la guía) porque el runner propio de staging puede tener bash 3.2 (macOS).

## 1. Crear el repositorio y subir el código

1. En GitHub abre la plantilla `urp-topicos-2026-2/demo-cicd` → **Use this template → Create a new repository**. Dueño: tu cuenta. Nombre: `demo-cicd`. **Public**. (Si ya lo creaste, usa ese.)
2. Abre un **Codespace** sobre tu repo, sube `demo-cicd-lab4.zip` al explorador de archivos y, en la terminal:

```bash
unzip -o demo-cicd-lab4.zip && rm demo-cicd-lab4.zip
```

3. Reemplaza `KrisD08` por tu usuario de GitHub (aquí se asumió `KrisD08` por el nombre de tu repo `KrisD08.github.io`; confírmalo):

```bash
grep -rlI 'KrisD08' --exclude-dir=node_modules --exclude-dir=.git . | xargs sed -i 's/KrisD08/KrisD08/g'
```

4. Valida en el Codespace antes de subir nada:

```bash
npm ci && npm ci --prefix api
npm run lint && npm run test:unit && npm run test:site
```

## 2. Preparar GitHub y tu máquina (una sola vez)

1. **Ambientes**: *Settings → Environments*: crea `dev`, y `staging` con **Required reviewers** = tú (desmarca *Prevent self-review* para poder aprobarte).
2. **Namespace y secreto de staging** en Rancher Desktop (PowerShell o Git Bash; necesitas `openssl`, que viene con Git Bash):

```bash
kubectl create namespace demo-staging
kubectl -n demo-staging create secret generic db-credenciales --from-literal=DB_PASSWORD="$(openssl rand -hex 16)"
```

3. **Runner propio** en tu laptop Windows: *Settings → Actions → Runners → New self-hosted runner → Windows*, sigue sus comandos (`config.cmd`, `run.cmd`) y déjalo corriendo. Debe tener Git Bash en el `PATH` (el job usa `shell: bash`). Tiene que ser en tu laptop, no en el Codespace, porque necesita tu Kubernetes.

## 3. PR 1: el pipeline base y su "antes" (B1, B6)

La rama ya trae como `.github/workflows/ci-cd.yml` el pipeline **de la guía** (secuencial, Gitleaks, kind, multi-arquitectura) con Trivy en `CRITICAL,HIGH`. Con él mides el "antes".

```bash
git checkout -b pipeline/base
git add -A && git commit -m "Pipeline base de la guía, Dockerfiles endurecidos, Dependabot"
git push -u origin pipeline/base
```

Abre el PR, espera el verde, haz merge. Mira el run de `main`: llega a `deploy-staging` y espera tu aprobación (**Review deployments**). Apruébalo.

- **Después del primer package**: en tu perfil → *Packages*, pon `demo-cicd-web`, `-api` y `-db` en **Public**.
- **Anota la duración de cada job** de este primer run en verde (pestaña Actions) en la tabla B6 del README: es tu "antes".
- **Si `security` sale en rojo por Trivy** (esperable en `db`, quizá en otras): abre el log, mira la tabla de HIGH/CRITICAL *con corrección*. Los Dockerfiles ya hacen `apk upgrade`, y `api` ya quita npm/corepack de la imagen. Lo que quede, acéptalo **una por una** en `.trivyignore` con el porqué (qué paquete, por qué no es explotable en este uso, fecha), como ya está `CVE-2025-68121`. **No** bajes la severidad ni pongas `exit-code: 0`.
- **Evidencia B1**: enlace al run aprobado y captura de `kubectl -n demo-staging get pods` con las imágenes `sha-<commit>`.

## 4. Proteger `main` y Dependabot (B1)

*Settings → Rules → Rulesets → New branch ruleset*, rama `main`, **Require a pull request** y **Require status checks**. Los checks se escogen por el **nombre del job** (solo aparecen después de haber corrido una vez):

`1. Lint (ESLint, HTMLHint, Hadolint)` · `2. SAST (Semgrep) y secretos (Gitleaks)` · `3. Pruebas unitarias y del sitio` · `4. Pruebas de integración (Compose)` · `5. Empaquetar y publicar (web|api|db)` · `6. Escaneo de imagen (web|api|db)`

(Cuando pases al pipeline final, el de SAST pasa a llamarse `2. SAST (Semgrep) y secretos (TruffleHog)`: actualiza el ruleset.)

Dependabot ya está configurado con `cooldown`. Cuando abra un PR, déjalo pasar por el pipeline y haz merge de al menos uno. En sus PR, `package` construye pero no publica y `security` se omite (Dependabot solo recibe un token de lectura).

## 5. PR 2: tu cambio, B4

```bash
git checkout main && git pull && git checkout -b feature/estadisticas
bash lab4-b4-estadisticas/aplicar.sh
git rm -r lab4-b4-estadisticas
git add -A && git commit -m "Endpoint /api/estadisticas y total en la página"
git push -u origin feature/estadisticas
```

PR → checks verdes → merge → aprueba STAGING → abre `http://localhost:30080` y captura el total junto al título.

## 6. PR 3: el pipeline final (B2, B5, B6, R1)

```bash
git checkout main && git pull && git checkout -b pipeline/final
cp docs/final/ci-cd.yml .github/workflows/ci-cd.yml
git add -A && git commit -m "Pipeline final: TruffleHog, k3d, resúmenes, paralelo, ZAP"
git push -u origin pipeline/final
```

Qué trae: TruffleHog en vez de Gitleaks y k3d en vez de kind (B2), `$GITHUB_STEP_SUMMARY` en cada job (B5), `lint/sast/test-unit/test-integration` en paralelo y solo `amd64` (B6), y ZAP contra DEV (R1). Actualiza el ruleset con el nombre nuevo del check de SAST.

- **ZAP en el primer run de `main` va a salir en rojo, a propósito**: nginx aún no tiene cabeceras de seguridad. Baja el artefacto `reporte-zap` del run y lee las alertas. Staging no se despliega hasta que esté en verde.
- Si `sha256sum -c` falla en el paso de k3d, el hash de `K3D_SHA256` no coincide con el de la release `v5.9.0` (cópialo de la página de la release en GitHub) y corrígelo.
- **B6**: anota los tiempos del primer run en verde del pipeline final (después del PR 4) y calcula el porcentaje. Debe ser ≥ 25 %. Si no llega, mira qué job domina (`package`, `deploy-dev`).

## 7. PR 4: corregir las alertas de ZAP (R1)

```bash
git checkout main && git pull && git checkout -b fix/cabeceras-zap
bash lab4-r1-zap/aplicar.sh && git rm -r lab4-r1-zap
git add -A && git commit -m "nginx: cabeceras de seguridad (CSP, nosniff, X-Frame-Options...)"
git push -u origin fix/cabeceras-zap
```

Tras el merge, vuelve a leer el reporte. Cada alerta que quede y decidas aceptar va en `.zap/rules.tsv` como `IGNORE` con su porqué (una por una). Ojo: `Cache-Control` y similares pueden aparecer; decide si corregir o aceptar. Evidencia: el run con el reporte, este PR y `.zap/rules.tsv`.

## 8. B2 y B3: romper a propósito (lo haces tú, con tus runs)

Cada uno en su rama y su PR; anota el enlace al run en rojo, el arreglo en verde y **en qué minuto** se detectó, en la tabla B3 del README.

| Etapa | Cómo |
|---|---|
| `lint` | Quita el `alt` de una imagen o el tag de un `FROM` |
| `sast` | `actions/checkout@v4` en vez del SHA, o quita el `cooldown` de Dependabot |
| `test-unit` | En `api/app.js` cambia un `400` por `200` |
| `test-integration` | En `web/nginx.conf` cambia `proxy_pass http://api:3000` por `:3001` |
| `security` | `node:22-alpine` → `node:16-alpine` |

B2 (cada herramienta nueva, en rojo): para **TruffleHog**, en una rama añade un archivo con un secreto de prueba con formato real (p. ej. un token `ghp_` falso de 36 caracteres); verifica que el job salga en rojo y **cierra el PR sin hacer merge** (el secreto quedaría en el historial de la rama, no en `main`). Si TruffleHog no lo detecta, prueba con otro formato de detector. Para **k3d**: rompe un manifiesto (p. ej. el `readinessProbe` de `k8s/base/api.yaml` a `/api/salud`): el rollout nunca termina y `deploy-dev` falla con el diagnóstico. Rellena la bitácora B2 con lo que compararías y por qué.

## 9. Retos

| Reto | Qué hay | Qué te toca |
|---|---|---|
| R1 ZAP | Hecho en los pasos 6 y 7 | Reglas y bitácora |
| R2 GitLab | `.gitlab-ci.yml` | Importar el repo a gitlab.com (Mirroring), ver el pipeline en verde y pulsar `deploy`; el registro de GitLab debe estar habilitado |
| R3 Observabilidad | `k8s/observabilidad/` | Ver abajo |
| R4 Argo CD | `retos/r4-argocd/` | Opcional; reemplaza `deploy-staging` (ver los archivos). Cambia el modelo del pipeline: hazlo al final y en su rama |
| R5 URL pública | `retos/r5-gke/` (GKE, recomendado: sin claves guardadas) y `retos/r5-render/` (alternativa) | Sigue el README de la carpeta elegida. En GKE: presupuesto con alertas primero y borra el clúster al terminar |
| R6 Terraform | `terraform/` | `terraform import` + `plan` sin cambios (ver `terraform/README.md`) |

**R3 paso a paso** (después de tener STAGING corriendo):

```bash
kubectl create namespace observabilidad
kubectl -n observabilidad create secret generic grafana-admin --from-literal=GF_SECURITY_ADMIN_PASSWORD="$(openssl rand -hex 12)"
kubectl apply -k k8s/observabilidad
```

Prometheus en `http://localhost:30090` (mira *Status → Targets* y *Alerts*), Grafana en `http://localhost:30300` (usuario `admin`, la contraseña del Secret; el dashboard RED ya está cargado). Para probar la alerta, tumba la base: `kubectl -n demo-staging scale deploy/db --replicas=0`. La API empieza a responder 5xx (incluidas las sondas de salud) y a ~1 minuto la alerta `TasaDeErrores5xxAlta` pasa a *Firing*; captura el dashboard y la alerta, y devuelve `--replicas=1`. La alerta vive en Prometheus; Alertmanager (quién avisa) queda como pregunta de la bitácora.

## 10. Entrega

README completo (reemplaza todos los `<PENDIENTE: ...>` con datos reales), enlaces a runs y PR, paquetes públicos, y el sub-issue de entrega. En la defensa oral te preguntan cómo pasar STAGING a GitOps: tienes `retos/r4-argocd/` como referencia.
