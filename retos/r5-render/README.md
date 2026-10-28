# Reto 5: aplicación pública en Render

## Qué se despliega y por qué así

| Pieza | En Render | Nota |
|---|---|---|
| `db` | Postgres gratuito (`demo-cicd-db`) | Reemplaza la imagen `demo-cicd-db`. **Expira a los 30 días** (14 de gracia). Sin backups |
| `api` | Servicio web desde `ghcr.io/KrisD08/demo-cicd-api:sha-...` | La misma imagen que pasó por DEV y STAGING |
| `web` | Servicio web desde `ghcr.io/KrisD08/demo-cicd-web-render:sha-...` | Misma imagen base de `web`, pero el proxy apunta a la URL pública de la API |

En el plan gratuito un servicio no recibe tráfico privado, por eso `web` llama a `api` por internet. Consecuencia que debes dejar escrita en la bitácora: **la API queda expuesta directamente**, incluido `/metrics` (nginx solo lo oculta en `web`). Los servicios gratuitos se duermen tras 15 minutos sin tráfico.

## Pasos (los haces tú, en tu cuenta)

1. Crea cuenta en render.com. Paquetes `demo-cicd-api` y `demo-cicd-web` en GHCR deben ser **Public**; el de `demo-cicd-web-render` también, después de que el workflow lo publique la primera vez (ver paso 5).
2. Reemplaza `KrisD08` y los `<PENDIENTE>` en `render.yaml` (el SHA completo de un run verde de `main`; la imagen `web-render` de ese SHA no existe todavía: ver paso 5).
3. En Render: **New → Blueprint** → tu repo → `retos/r5-render/render.yaml`. Se crean la base y los dos servicios.
4. Crea las tablas **una sola vez** contra la base de Render (cadena *External Database URL* de la base; no la pegues en ningún archivo):

```bash
psql "<External Database URL>" -f db/init/01-crear-tablas.sql
psql "<External Database URL>" -f db/init/02-datos-ejemplo.sql   # opcional
```

5. Primer despliegue: el servicio `demo-cicd-web` no arrancará hasta que exista una imagen `demo-cicd-web-render`. Haz primero el paso 6 y 7, deja que el workflow la publique (fallará el aviso a Render si aún no hay hooks; está bien) y vuelve a lanzar.
6. En GitHub → *Settings → Environments → New environment* `publico`. Ahí:
   - **Variables**: `RENDER_API_HOST` = el host de tu API (ej. `demo-cicd-api.onrender.com`, **sin** `https://`) y `RENDER_WEB_URL` = `https://<tu web>.onrender.com`. (Los nombres reales los asigna Render: míralos en su panel.)
   - **Secrets**: `RENDER_DEPLOY_HOOK_API` y `RENDER_DEPLOY_HOOK_WEB`, la URL de *Settings → Deploy Hook* de cada servicio en Render.
7. Activa el workflow: `cp retos/r5-render/deploy-render.yml .github/workflows/deploy-render.yml`, PR y merge. Desde ahí, cada push a `main` que llegue en verde hasta STAGING se publica en la URL pública.

## Lo que este camino no cumple (dilo en la bitácora)

- El criterio pide "sin una clave de larga duración": Render **no tiene OIDC**. Se usan deploy hooks: alcance mínimo (un servicio, solo disparan un despliegue), ambiente `publico` y rotables con *Regenerate Hook*, pero **no caducan**. Alternativa que sí cumple del todo: GKE Autopilot con Workload Identity Federation.
- Render no avisa cuándo termina el despliegue sin otra credencial (su API). El workflow espera el `/api/health` y corre el smoke test, pero si la versión vieja sigue viva responde igual.

## Evidencia a reunir

La URL pública, el run de `Deploy público (Render)`, y capturas del ambiente `publico` (secretos y variables) y de los deploy hooks en Render. Fuentes: render.com/docs/free y render.com/docs/deploy-hooks.