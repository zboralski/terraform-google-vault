# storage.tf

# Generate a random ID for Vault resources
resource "random_id" "vault" {
  byte_length = 2
}

# Create a service account for Vault with KMS auto-unseal
resource "google_service_account" "vault" {
  project      = var.project
  account_id   = var.vault_service_account_id
  display_name = "Vault Service Account for KMS auto-unseal"
}

# Create a GCS storage bucket for Vault data
resource "google_storage_bucket" "vault" {
  name          = local.vault_storage_bucket_name
  project       = var.project
  location      = var.vault_storage_bucket_location
  force_destroy = var.bucket_force_destroy
}

# Grant the Vault service account the necessary permissions on the GCS bucket
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.vault.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vault.email}"
}

resource "google_cloud_run_domain_mapping" "custom_domain" {
  name     = var.domain
  project  = var.project
  location = var.location

  metadata {
    namespace = var.project
  }

  spec {
    route_name = var.name
  }
  depends_on = [google_cloud_run_service.default]
}