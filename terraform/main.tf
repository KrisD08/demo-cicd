# Reto 6: la protección de main y los ambientes del repositorio, como código.
# Autenticación: variable de entorno GITHUB_TOKEN con un token (alcance: administración del repositorio).
# Nunca en este archivo ni en un .tfvars versionado.
terraform {
  required_version = ">= 1.6"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }
}

variable "propietario" {
  description = "Usuario u organización dueño del repositorio"
  type        = string
}

variable "repositorio" {
  type    = string
  default = "demo-cicd"
}

variable "revisor" {
  description = "Usuario de GitHub que aprueba los despliegues a STAGING"
  type        = string
}

provider "github" {
  owner = var.propietario
}

data "github_user" "revisor" {
  username = var.revisor
}

# Los contextos son los nombres (name:) de los jobs de ci-cd.yml, tal como aparecen en los checks del PR.
locals {
  checks_requeridos = [
    "1. Lint (ESLint, HTMLHint, Hadolint)",
    "2. SAST (Semgrep) y secretos (TruffleHog)",
    "3. Pruebas unitarias y del sitio",
    "4. Pruebas de integración (Compose)",
    "5. Empaquetar y publicar (web)",
    "5. Empaquetar y publicar (api)",
    "5. Empaquetar y publicar (db)",
    "6. Escaneo de imagen (web)",
    "6. Escaneo de imagen (api)",
    "6. Escaneo de imagen (db)",
  ]
}

resource "github_repository_environment" "dev" {
  repository  = var.repositorio
  environment = "dev"
}

resource "github_repository_environment" "staging" {
  repository          = var.repositorio
  environment         = "staging"
  prevent_self_review = false # quien trabaja solo se aprueba a sí mismo (como pide el Paso 6 de la guía)

  reviewers {
    users = [data.github_user.revisor.id]
  }
}

resource "github_repository_ruleset" "main" {
  name        = "main"
  repository  = var.repositorio
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = 0
    }

    required_status_checks {
      dynamic "required_check" {
        for_each = local.checks_requeridos
        content {
          context = required_check.value
          integration_id = 15368
        }
      }
    }
  }
}