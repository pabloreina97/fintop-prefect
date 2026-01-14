terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Obtener información del proyecto
data "google_project" "project" {}

# Artifact Registry para imágenes Docker
resource "google_artifact_registry_repository" "flows" {
  repository_id = "etl-flows"
  description   = "Docker images for ETL flows"
  format        = "DOCKER"
  location      = var.gcp_region
}

# Service Account para Cloud Run
resource "google_service_account" "etl" {
  account_id   = "etl-cloud-run"
  display_name = "ETL Cloud Run"
  description  = "Service account for ETL Cloud Run jobs"
}

# Permiso: Invocar Cloud Run Jobs
resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.gcp_project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.etl.email}"
}

# Permiso: Leer imágenes del Artifact Registry (para el ETL service account)
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.gcp_project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.etl.email}"
}

# Permiso: Cloud Run Service Agent necesita leer imágenes del Artifact Registry
resource "google_project_iam_member" "cloud_run_agent_artifact_registry" {
  project = var.gcp_project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

# Cloud Run Job - ETL de transacciones
resource "google_cloud_run_v2_job" "bank_etl" {
  name     = "bank-transactions-etl"
  location = var.gcp_region

  template {
    template {
      containers {
        image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.flows.repository_id}/fintop:latest"

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "SUPABASE_URL"
          value = var.supabase_url
        }
        env {
          name  = "SUPABASE_SERVICE_KEY"
          value = var.supabase_service_key
        }
        env {
          name  = "GC_SECRET_ID"
          value = var.gc_secret_id
        }
        env {
          name  = "GC_SECRET_KEY"
          value = var.gc_secret_key
        }
      }

      service_account = google_service_account.etl.email
      timeout         = "300s"
    }
  }

  depends_on = [google_artifact_registry_repository.flows]
}

# Cloud Scheduler - Ejecuta el ETL a las 6:00 AM
resource "google_cloud_scheduler_job" "bank_etl_daily" {
  name        = "bank-etl-daily"
  description = "Ejecuta ETL de transacciones bancarias diariamente a las 6 AM"
  schedule    = "0 6 * * *"
  time_zone   = "Europe/Madrid"

  http_target {
    uri         = "https://${var.gcp_region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.gcp_project}/jobs/${google_cloud_run_v2_job.bank_etl.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.etl.email
    }
  }

  depends_on = [google_cloud_run_v2_job.bank_etl]
}
