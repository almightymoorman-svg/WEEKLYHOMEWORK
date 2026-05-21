variable "project_id" {
  type        = string
  description = "gcp project id"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/24"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "disk_image" {
  type    = string
  default = "debian-cloud/debian-12"
}

variable "mig_size" {
  type    = number
  default = 2
}

variable "env" {
  type    = string
  default = "dev"
}

variable "app" {
  type    = string
  default = "web"
}
