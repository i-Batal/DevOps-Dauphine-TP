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

variable "db_user" {
  description = "Nom de l'utilisateur de la base de données"
  default     = "wordpress"
}

variable "db_password" {
  description = "Mot de passe de l'utilisateur de la base de données"
  default     = "ilovedevops"
}

variable "db_name" {
  description = "Nom de la base de données"
  default     = "wordpress"
}

variable "db_host" {
  description = "Hôte de la base de données (service MySQL ou adresse IP)"
  default     = "mysql-service"
}



