terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "wissahickon-dev-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Service Account Setup
resource "google_service_account" "wis_backend_api_sa" {
  account_id   = "wis-backend-api-sa"
  display_name = "WIS Backend API service account for core services"
}

resource "google_service_account" "wis_frontend_ui_sa" {
  account_id   = "wis-frontend-ui-sa"
  display_name = "WIS Frontend UI service account for web interface"
}

# IAM Bindings
resource "google_project_iam_member" "backend_cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.wis_backend_api_sa.email}"
}

resource "google_project_iam_member" "backend_secretmanager" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.wis_backend_api_sa.email}"
}

resource "google_project_iam_member" "frontend_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.wis_frontend_ui_sa.email}"
}

# Cloud SQL Instance
resource "google_sql_database_instance" "wis_dev_db" {
  name             = "wis-dev-db"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled = false
    }

    ip_configuration {
      ipv4_enabled = true
      # For development, allowing all. Should be restricted in production
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "wis_dev" {
  name     = "wis_dev"
  instance = google_sql_database_instance.wis_dev_db.name
}

# Secret Manager Secrets
resource "google_secret_manager_secret" "flask_secret" {
  secret_id = "wis-flask-secret-key"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "wis-jwt-secret-key"

  replication {
    automatic = true
  }
}

# Cloud Storage for Frontend
resource "google_storage_bucket" "frontend_assets" {
  name          = "wissahickon-dev-frontend-assets"
  location      = var.region
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}
