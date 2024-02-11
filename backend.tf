terraform {
  backend "gcs" {
    bucket = "pal-server-terraform-backend"
    prefix = "terraform/state"
  }
}