terraform {
  required_version = ">= 1.3.0"
  
  backend "gcs" {
    bucket  = "dauphine-tpnote-ib"  # Le nom du bucket
    prefix  = "terraform/state"       # Chemin "logique" dans le bucket
  }

  # Si besoin, vous pouvez spécifier un provider requérant une version minimale
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

resource "google_project_service" "enable_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "artifactregistry.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudbuild.googleapis.com",
  ])

  project = var.project_id
  service = each.key
  
  # On ne désactive pas le service à la destruction de la ressource
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "website_tools" {
  provider      = google
  project       = var.project_id
  location      = var.region
  repository_id = "website-tools"
  format        = "DOCKER"
  description   = "Dépôt pour nos images WordPress"
}

resource "google_sql_database" "wordpress_db" {
  name     = "wordpress"
  instance = "main-instance"
}

resource "google_sql_user" "wordpress_user" {
  name     = "wordpress"
  instance = "main-instance"
  password = "ilovedevops"
}
