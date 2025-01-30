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

    "run.googleapis.com" #ajouté pour la partie 3

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

resource "google_cloud_run_service" "wordpress" {
  name     = "serveur-wordpress"
  location = "us-central1"
  project  = var.project_id

  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/tp5-devops-dauphine/website-tools/wordpress-custom" # Remplacez par votre image Docker
        ports {
          container_port = 80
        }
        env {
          name  = "WORDPRESS_DB_USER"
          value = "wordpress"
        }
        env {
          name  = "WORDPRESS_DB_PASSWORD"
          value = "ilovedevops"
        }
        env {
          name  = "WORDPRESS_DB_NAME"
          value = "wordpress"
        }
        env {
          name  = "WORDPRESS_DB_HOST"
          value = "104.154.20.193" # Adresse IP publique MySQL
        }
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.wordpress.location
  project     = google_cloud_run_service.wordpress.project
  service     = google_cloud_run_service.wordpress.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

