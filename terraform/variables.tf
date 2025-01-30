variable "project_id" {
  type        = string
  description = "tp5-devops-dauphine"
}

variable "region" {
  type        = string
  description = "Région GCP à utiliser"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Zone GCP à utiliser"
  default     = "us-central1-a"
}
