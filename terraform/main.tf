terraform {
  required_version = ">= 1.3.0"
  
  backend "gcs" {
    bucket  = "dauphine-tpnote-ib"  # Le nom du bucket
    prefix  = "terraform/state"     # Chemin "logique" dans le bucket
  }

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
    "run.googleapis.com"
  ])

  project = var.project_id
  service = each.key
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
        image = "us-central1-docker.pkg.dev/tp5-devops-dauphine/website-tools/wordpress-custom"
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
          value = "104.154.20.193"  # Adresse IP publique MySQL
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

data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = "gke-dauphine"
  location = "us-central1-a"
}

provider "kubernetes" {
  host                   = data.google_container_cluster.my_cluster.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)
}

# Déploiement MySQL
resource "kubernetes_deployment" "mysql" {
  metadata {
    name = "mysql"
    labels = {
      app = "mysql"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mysql"
      }
    }
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        container {
          name  = "mysql"
          image = "mysql:5.7"
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "rootpassword"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "wordpress"
          }
          env {
            name  = "MYSQL_USER"
            value = "wordpress"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = "ilovedevops"
          }
          port {
            container_port = 3306
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql-service"
  }
  spec {
    selector = {
      app = "mysql"
    }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "LoadBalancer"
  }
}


# Déploiement WordPress
resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress"
    labels = {
      app = "wordpress"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "wordpress"
      }
    }
    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }
      spec {
        container {
          name  = "wordpress"
          image = "us-central1-docker.pkg.dev/tp5-devops-dauphine/website-tools/wordpress-custom"
          env {
            name  = "WORDPRESS_DB_HOST"
            value = "mysql-service"
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
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress" {
  metadata {
    name = "wordpress-service"
  }
  spec {
    selector = {
      app = "wordpress"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}


