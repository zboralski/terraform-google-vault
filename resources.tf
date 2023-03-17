# resource.tf

# Create a KMS Key Ring
resource "google_kms_key_ring" "vault" {
  name     = local.vault_kms_keyring_name
  project  = var.project
  location = var.location
}

# Create a Crypto Key for the Key Ring with a specified rotation period
resource "google_kms_crypto_key" "vault" {
  name            = "${var.name}-key"
  key_ring        = google_kms_key_ring.vault.id
  rotation_period = var.vault_kms_key_rotation

  version_template {
    algorithm        = var.vault_kms_key_algorithm
    protection_level = var.vault_kms_key_protection_level
  }
}

# Grant the Vault Service Account access to the KMS Key Ring with the "owner" role
resource "google_kms_key_ring_iam_member" "vault" {
  key_ring_id = google_kms_key_ring.vault.id
  role        = "roles/owner"
  member      = "serviceAccount:${google_service_account.vault.email}"
}

# Create a Google IAM policy data source with a "roles/run.invoker" role allowing "allUsers" access
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Apply the IAM policy to the Google Cloud Run service to allow public (unauthenticated) access
resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
