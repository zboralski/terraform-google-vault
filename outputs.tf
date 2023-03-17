# output.tf

output "status" {
  description = "The current status of the Cloud Run domain mapping."
  value       = google_cloud_run_domain_mapping.custom_domain.status
}

output "app_url" {
  value       = google_cloud_run_service.default.status[0].url
  description = "The URL of the deployed Vault Cloud Run service."
}

output "service_account_email" {
  value       = google_service_account.vault.email
  description = "The email address of the Vault service account used for KMS auto-unseal."
}

output "cloud_run_load_balancer_ip" {
  value       = module.cloud_lb_ip.address
  description = "The IP address of the Cloud Run load balancer."
}

output "vault_storage_bucket_name" {
  value       = local.vault_storage_bucket_name
  description = "The name of the GCS storage bucket used for Vault storage."
}
