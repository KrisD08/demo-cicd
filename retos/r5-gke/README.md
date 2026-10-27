# Reto 5 con GKE Autopilot: URL pública sin claves guardadas

La misma aplicación de STAGING, en GKE, con web detrás de un LoadBalancer (IP pública). La base de datos es el contenedor `db` con su volumen, igual que en STAGING.

## Pasos (los haces tú, en tu proyecto de Google Cloud)

1. **Antes de crear nada, protege tus USD 50**: en *Facturación → Presupuestos y alertas* crea un presupuesto con alertas. Revisa el costo estimado de Autopilot y del balanceador en la calculadora de precios de Google Cloud: no lo verifiqué, así que no hay cifras aquí. Piensa en este ambiente como de prueba: **bórralo al tener tu evidencia** (paso 7).
2. Abre Cloud Shell (o gcloud en tu máquina), clona tu repo y corre una vez:

```bash
PROJECT_ID=<tu proyecto> REGION=<región cercana> USUARIO=<usuario de GitHub> bash retos/r5-gke/configurar-gcp.sh
```

   Crea el clúster Autopilot, una cuenta de servicio con permisos mínimos, la federación de identidad (solo acepta tu repositorio y el ambiente `publico`) y el Secret de la base. Al final imprime cinco valores.
3. En GitHub → *Settings → Environments → New environment* `publico`. Pon esos cinco valores como **Variables** (no son secretos; no hay ningún secreto).
4. Los paquetes `demo-cicd-web`, `-api` y `-db` deben ser **Public** (ya lo hiciste en el Paso 4 de la guía).
5. Activa el workflow: `cp retos/r5-gke/deploy-gke.yml .github/workflows/deploy-gke.yml`, PR y merge. Desde ahí, cada push a `main` que llegue en verde hasta STAGING se publica en GKE.
6. Evidencia: la URL que muestra el resumen del run, el run en verde y una captura de la configuración de identidad (el *workload identity pool/provider* y la condición de atributos del provider).
7. Al terminar: `gcloud container clusters delete demo-cicd --region <región>` y verifica en *Balanceo de carga* que no quede nada.

## Cosas que no verifiqué y debes mirar en el primer run

- **Recursos de los pods:** Autopilot ajusta los requests/limits de los pods a sus mínimos. Si un pod se reinicia por memoria, mira `kubectl -n demo-publico describe pod` y sube los límites en un parche del overlay `k8s/overlays/publico`.
- **El plugin de autenticación** `gke-gcloud-auth-plugin` se instala con `setup-gcloud`. Si el paso falla, lee su log.
- **La URL es `http://<IP>`**, sin HTTPS ni dominio: suficiente para el reto, no para producción.
- **Volumen de la base:** el PVC usa la clase de almacenamiento por defecto del clúster. Si queda en `Pending`, revisa `kubectl -n demo-publico describe pvc`.

## Por qué cumple el criterio

No hay ninguna clave de larga duración en GitHub. El job pide un token OIDC (permiso `id-token: write`, solo en ese job) y Google lo cambia por credenciales temporales. Ese cambio solo se concede si el token viene de tu repositorio *y* de un job con `environment: publico` (la condición del provider). Con una clave JSON, cualquiera que la robara tendría acceso hasta que la rotaras; aquí no hay nada que robar.