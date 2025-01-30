provider "google" {
  project = var.project_id  # identifiant GCP
  region  = var.region      # ex: "us-central1"
  zone    = var.zone        # ex: "us-central1-a"
}
