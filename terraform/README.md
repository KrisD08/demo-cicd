# Reto 6: Terraform para el repositorio

```bash
export GITHUB_TOKEN=<tu token, nunca en un archivo>
cd terraform
terraform init
terraform plan -var propietario=KrisD08 -var revisor=KrisD08
```

"Cero cambios" exige que lo que ya configuraste a mano coincida con este código. Importa lo existente y vuelve a hacer `plan`:

```bash
terraform import -var propietario=KrisD08 -var revisor=KrisD08 github_repository_environment.dev demo-cicd:dev
terraform import -var propietario=KrisD08 -var revisor=KrisD08 github_repository_environment.staging demo-cicd:staging
terraform import -var propietario=KrisD08 -var revisor=KrisD08 github_repository_ruleset.main demo-cicd:<ID del ruleset>
```

El ID del ruleset sale de la URL de *Settings → Rules → Rulesets → main* (`.../rules/<ID>`).
Si `plan` muestra diferencias, edita `main.tf` hasta que coincida con tu configuración real (o corrige la configuración): ese es el ejercicio.
Estado: se queda local (`terraform.tfstate`, ignorado por Git). En el aperitivo de la Semana 07 se verá dónde guardarlo de verdad.