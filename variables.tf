variable "name" {
  description = "Application name."
  type        = string
}

variable "location" {
  description = "Google location where resources are to be created."
  type        = string
}

variable "project" {
  description = "Google project ID."
  type        = string
}

variable "ingress" {
  description = "Ingress setting for the Cloud Run service"
  type        = string
  default     = "all"
}

variable "vault_image" {
  description = "Vault docker image (i.e. us.gcr.io/vault-226618/vault:latest)."
  type        = string
}

variable "bucket_force_destroy" {
  description = "CAUTION: Set force_destroy for Storage Bucket. This is where the vault data is stored. Setting this to true will allow terraform destroy to delete the bucket."
  type        = bool
  default     = false
}

variable "container_concurrency" {
  description = "Max number of connections per container instance."
  type        = number
  default     = 80 # Max per Cloud Run Documentation
}

variable "vpc_connector" {
  description = "Serverless VPC access connector."
  type        = string
  default     = ""
}

variable "vault_ui" {
  description = "Enable Vault UI."
  type        = bool
  default     = false
}

variable "vault_api_addr" {
  description = "Full HTTP endpoint of Vault Server if using a custom domain name. Leave blank otherwise."
  type        = string
  default     = ""
}

variable "vault_kms_keyring_name" {
  description = "Name of the Google KMS keyring to use."
  type        = string
  default     = ""
}

variable "vault_kms_key_rotation" {
  description = "The period for KMS key rotation."
  type        = string
  default     = "7776000s"
}

variable "vault_kms_key_algorithm" {
  description = "The cryptographic algorithm to be used with the KMS key."
  type        = string
  default     = "GOOGLE_SYMMETRIC_ENCRYPTION"
}

variable "vault_kms_key_protection_level" {
  description = "The protection level to be used with the KMS key."
  type        = string
  default     = "SOFTWARE"
}

variable "vault_service_account_id" {
  description = "ID for the service account to be used. This is the part of the service account email before the `@` symbol."
  type        = string
  default     = "vault-sa"
}

variable "vault_storage_bucket_name" {
  description = "Storage bucket name to be used."
  type        = string
  default     = ""
}

variable "vault_storage_bucket_location" {
  description = "The GCS location of the storage bucket"
  type        = string
  default     = "US"
}

variable "authorized_ip_ranges" {
  description = "List of authorized IP ranges"
  type        = list(string)
}

variable "lb_domains" {
  description = "List of domains for managed SSL certificate"
  type        = list(string)
  default     = []
}

variable "domain" {
  type       = string
  description = "Domain name for the Vault UI"
}

variable "env_secrets" {
  description = "A map of environment variable names to secret IDs"
  type        = map(string)
  default = {
    # MY_SECRET_1 = "my-secret-id-1"
    # MY_SECRET_2 = "my-secret-id-2"
  }
}
