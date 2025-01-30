terraform {
  required_version = ">= 1.3.0"
  
  backend "gcs" {
    bucket  = " dauphine-tpnote-ib"  # Le nom du bucket
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
