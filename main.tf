# main.tf

module "cloud_lb_ip" {
  source  = "zboralski/cloudrun-lb/google"
  version = "~> 0.1.0"

  project                         = var.project
  location                        = var.location
  name                            = "${var.name}-load-balancer"
  service                         = google_cloud_run_service.default.name
  authorized_ip_ranges            = var.authorized_ip_ranges
  managed_ssl_certificate_domains = var.lb_domains
}

resource "google_project_service" "services" {
  for_each = toset(local.services)

  project            = var.project
  service            = each.value
  disable_on_destroy = false
}

data "google_cloud_run_service" "instance" {
  name     = var.name
  project  = var.project
  location = var.location
}

# Google Cloud Run Service
resource "google_cloud_run_service" "default" {
  name                       = var.name
  project                    = var.project
  location                   = var.location
  autogenerate_revision_name = true

  metadata {
    namespace = var.project
    annotations = {
      "run.googleapis.com/ingress" = var.ingress
    }
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = 1 # HA not Supported
        "run.googleapis.com/vpc-access-connector" = var.vpc_connector != "" ? var.vpc_connector : null
        "run.googleapis.com/sandbox"              = "gvisor"
        "run.googleapis.com/secrets"              = local.run_googleapis_com_secrets
      }
    }
    spec {
      service_account_name  = var.vault_service_account_id
      container_concurrency = var.container_concurrency
      containers {
        image   = var.vault_image
        command = ["/usr/local/bin/docker-entrypoint.sh"]
        args    = ["server"]

        env {
          name  = "SKIP_SETCAP"
          value = "true"
        }

        env {
          name  = "VAULT_LOCAL_CONFIG"
          value = local.vault_config
        }

        env {
          name  = "VAULT_API_ADDR"
          value = var.vault_api_addr
        }

        dynamic "env" {
          for_each = local.secret_uuids
          content {
            name = env.key
            value_from {
              secret_key_ref {
                name = env.value
                key  = "latest"
              }
            }
          }
        }

        resources {
          limits = {
            "cpu"    = "1000m"
            "memory" = "256Mi"
          }
          requests = {
            "cpu"    = "200m"
            "memory" = "128Mi"
          }
        }
      }
    }
  }
}

# Extract FQDN from service URL
locals {
  services = [
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ]
  hostname = replace(google_cloud_run_service.default.status[0].url, "^https?://([^/]+)/?$", "$1")

  # Generate the Vault configuration as a JSON string
  vault_config = jsonencode(
    {
      "storage" = {
        "gcs" = {
          "bucket"     = local.vault_storage_bucket_name
          "ha_enabled" = "false"
        }
      },
      "seal" = {
        "gcpckms" = {
          "project"    = var.project,
          "region"     = var.location,
          "key_ring"   = local.vault_kms_keyring_name,
          "crypto_key" = google_kms_crypto_key.vault.name
        }
      },
      "default_lease_ttl"            = "168h",
      "default_max_request_duration" = "90s",
      "max_lease_ttl"                = "720h",
      "disable_clustering"           = "true",
      "disable_mlock"                = "true",
      "listener" = {
        "tcp" = {
          "address"     = "0.0.0.0:8080",
          "tls_disable" = "1"
        }
      },
      "ui" = var.vault_ui
    }
  )

  # Set the Vault KMS keyring name or generate a new one if not provided
  vault_kms_keyring_name = var.vault_kms_keyring_name != "" ? var.vault_kms_keyring_name : "${var.name}-${lower(random_id.vault.hex)}-kr"

  # Set the Vault storage bucket name or generate a new one if not provided
  vault_storage_bucket_name = var.vault_storage_bucket_name != "" ? var.vault_storage_bucket_name : "${var.name}-${lower(random_id.vault.hex)}-sb"
}

resource "random_uuid" "secrets" {
  for_each = var.env_secrets
}

locals {
  # esu == existing_secret_uuids
  esu_string = lookup(data.google_cloud_run_service.instance.template[0].metadata[0].annotations, "run.googleapis.com/secrets", "")
  esu_parts = local.esu_string == ""? []: split(",", local.esu_string)
  # Key should be the second part, value should be the first part
  esu_values = local.esu_string == ""? [] : [for part in local.esu_parts : split(":", part)[0]]
  esu_keys = local.esu_string == ""? [] : [for part in local.esu_parts : split(":", part)[1]]
  esu = local.esu_string == ""? {} : zipmap(local.esu_keys, local.esu_values)
  # Choose the existing uuid or a new one if it doesn't exist
  secret_uuids                = { for env_name, secret_id in var.env_secrets : env_name => (lookup(local.esu, secret_id, "") == ""? "secret-${random_uuid.secrets[env_name].result}" : local.esu[secret_id])}
  secret_mappings            = { for env_name, secret_id in var.env_secrets : env_name => "${local.secret_uuids[env_name]}:${secret_id}" }
  run_googleapis_com_secrets = join(",", values(local.secret_mappings))
}
