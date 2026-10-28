#!/usr/bin/env bash
# Reto 5 (GKE): deja Google Cloud listo para que GitHub Actions despliegue SIN ninguna clave guardada.
# Lo corre UNA vez una persona, con gcloud autenticado (Cloud Shell sirve). Léelo entero antes de ejecutarlo.
# Uso: PROJECT_ID=<tu proyecto> REGION=<región> USUARIO=<usuario de GitHub> bash retos/r5-gke/configurar-gcp.sh
set -euo pipefail

: "${PROJECT_ID:?define PROJECT_ID}" "${REGION:?define REGION}" "${USUARIO:?define USUARIO}"
REPO="${USUARIO}/demo-cicd"
CLUSTER="demo-cicd"
SA="gha-deploy"
SA_EMAIL="${SA}@${PROJECT_ID}.iam.gserviceaccount.com"
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

gcloud config set project "$PROJECT_ID"
gcloud services enable container.googleapis.com iamcredentials.googleapis.com

# 1. Clúster Autopilot (Google administra los nodos; pagas por lo que piden los pods).
gcloud container clusters create-auto "$CLUSTER" --region "$REGION"

# 2. Cuenta de servicio que usará el pipeline: solo puede trabajar con objetos de Kubernetes en GKE.
gcloud iam service-accounts create "$SA" --display-name "GitHub Actions deploy (demo-cicd)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:${SA_EMAIL}" --role roles/container.developer

# 3. Workload Identity Federation: GitHub presenta un token OIDC de corta vida y Google lo cambia por credenciales
#    temporales. Solo vale si viene de TU repositorio y del job que usa el ambiente "publico".
gcloud iam workload-identity-pools create github --location global --display-name "GitHub Actions"
gcloud iam workload-identity-pools providers create-oidc github-repo \
  --location global --workload-identity-pool github \
  --issuer-uri "https://token.actions.githubusercontent.com" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition "assertion.repository=='${REPO}' && assertion.sub=='repo:${REPO}:environment:publico'"

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.repository/${REPO}"

# 4. Namespace y Secret de la base de datos: se crean a mano, el pipeline nunca los toca.
gcloud container clusters get-credentials "$CLUSTER" --region "$REGION"
kubectl create namespace demo-publico
kubectl -n demo-publico create secret generic db-credenciales --from-literal=DB_PASSWORD="$(openssl rand -hex 16)"

echo
echo "Listo. Estos valores van como VARIABLES (no secretos) del ambiente 'publico' en GitHub:"
echo "  GCP_PROJECT_ID       = ${PROJECT_ID}"
echo "  GKE_CLUSTER          = ${CLUSTER}"
echo "  GKE_REGION           = ${REGION}"
echo "  GCP_SERVICE_ACCOUNT  = ${SA_EMAIL}"
echo "  GCP_WIF_PROVIDER     = projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/providers/github-repo"