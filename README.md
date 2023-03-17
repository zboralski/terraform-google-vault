## Features

This Terraform module deploys a highly available [HashiCorp Vault](https://www.vaultproject.io/) cluster on [Google Cloud Run](https://cloud.google.com/run/) using [Google Cloud Storage](https://cloud.google.com/storage/) as the backend storage and [Google Cloud KMS](https://cloud.google.com/kms/) for auto-unsealing. It also includes optional features such as enabling Vault UI and setting up a load balancer with a managed SSL certificate.

## Prerequisites

This module requires the following Google Cloud services to be enabled and configured:

- Google Cloud Run
- Google Cloud Storage
- Google Cloud KMS

## Architecture

The module creates the following resources:

- Google Cloud Run Service: The Vault cluster is deployed as a Cloud Run service. It includes a container running the Vault server and a Cloud Storage bucket for data storage. The service is automatically scaled to one container instance, and requests to the service are automatically routed to the available instance(s).
- Google Cloud KMS: A KMS key ring and a cryptographic key are created for Vault's auto-unsealing feature.
- Google Cloud Storage: A bucket is created to store Vault's data.
- Google Cloud Run Domain Mapping: A domain name can be provided to map the Vault service to a custom domain.
- Google Cloud Load Balancer: A load balancer can be created with a managed SSL certificate.

```text
┌───────────────────────────────────────────────────────┐
│                                                       │
│                     Google Cloud                      │
│                                                       │
│   ┌───────────────────────┐ ┌──────────────────────┐  │
│   │ Google Cloud Run      │ │ Google Cloud KMS     │  │
│   │ Service with Vault    │ │ Key ring and key for │  │
│   │                       │ │ Vault's auto-unseal  │  │
│   └───────────────────────┘ └──────────────────────┘  │
│                       │                │              │
│   ┌────────────────────────────────────────────────┐  │
│   │ Google Cloud Storage                           │  │
│   │ Bucket for Vault data                          │  │
│   └────────────────────────────────────────────────┘  │
│                       │                │              │
│   ┌────────────────────────────────────────────────┐  │
│   │ Google Cloud Run Domain Mapping                │  │
│   │ Optional custom domain mapping for Vault       │  │
│   └────────────────────────────────────────────────┘  │
│                       │                               │
│   ┌────────────────────────────────────────────────┐  │
│   │ Google Cloud Load Balancer                     │  │
│   │ Optional load balancer with managed SSL cert   │  │
│   └────────────────────────────────────────────────┘  │
│                                                       │
└───────────────────────────────────────────────────────┘
```

## Usage

To use this module, add the following code to your Terraform configuration:

```hcl

provider "google" {
  project = "belua-vault-us"
  region  = "us-central1"
}

data "google_client_config" "current" {}

module "vault" {
  source = "zboralski/vault/google"
  version = "0.1.0"

  providers = {
    google = google
  }

  # Set the project and location using data from the Google client config
  project  = data.google_client_config.current.project
  location = data.google_client_config.current.region

  name = "my-vault"
  # Set the Vault image

   # Set the Vault image
  vault_image = "gcr.io/${data.google_client_config.current.project}/vault:latest"

   # Set the Vault service account ID
  vault_service_account_id = "my-vault-sa"

  # Set the authorized IP ranges for accessing the Vault
  authorized_ip_ranges = ["0.0.0.0/0"]

  # Set the hostname
  domain = "vault-cloudrun.example.com"

  # Set the hostnames for the load balancer
  lb_domains = ["vault.example.com"]

  # Deny access from all IP addresses.
  # ingress = "internal-and-cloud-load-balancing"

  # Allow access from all IP addresses.
  ingress = "all"

  # Enable the Vault UI
  vault_ui = true
}
```

## Architecture

The module creates the following resources:

- Google Cloud Run Service: The Vault cluster is deployed as a Cloud Run service. It includes a container running the Vault server and a Cloud Storage bucket for data storage. The service is automatically scaled to one container instance, and requests to the service are automatically routed to the available instance(s).
- Google Cloud KMS: A KMS key ring and a cryptographic key are created for Vault's auto-unsealing feature.
- Google Cloud Storage: A bucket is created to store Vault's data.
- Google Cloud Run Domain Mapping: An optional domain name can be provided to map the Vault service to a custom domain.
- Google Cloud Load Balancer: load balancer with managed SSL certificates.

## Getting Started

To get started, a Google Cloud Project is needed. This should be created ahead
of time or using Terraform, but is outside the scope of this module. This
project ID is provided to the module invocation and a basic implementation
would look like the following:

```hcl
provider "google" {}

data "google_client_config" "current" {}

# Usage
To use this module, add the following code to your Terraform configuration:

module "vault" {
  source            = "github.com/zboralski/terraform-google-vault"
  project           = "<project>"
  location          = "<location>"
  domain            = "<vault-domain>"
  lb_domains        = ["<load-balancer-domain-1>", "<load-balancer-domain-2>"]
  vault_image       = "us.gcr.io/vault-226618/vault:latest"
  vault_ui          = true
  ingress           = "internal-and-cloud-load-balancing"
  container_concurrency = 100
  authorized_ip_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  vault_storage_bucket_name = "<vault-bucket-name>"
  vault_storage_bucket_location = "<vault-bucket-location>"
  vault_kms_keyring_name = "<vault-kms-keyring-name>"
  vault_kms_key_rotation = "<vault-kms-key-rotation>"
  vault_kms_key_algorithm = "<vault-kms-key-algorithm>"
  vault_kms_key_protection_level = "<vault-kms-key-protection-level>"
  vault_service_account_id = "<vault-service-account-id>"
}
```

After creating the resources, the Vault instance may be initialized.

Set the `VAULT_ADDR` environment variable. See [Vault URL](#vault-url).

```bash
export VAULT_ADDR=https://vault-jsn3uj5s1c-sg.a.run.app
```

Ensure the vault is operational (might take a minute or two), uninitialized and
sealed.

```bash
$ vault status
Key                      Value
---                      -----
Recovery Seal Type       gcpckms
Initialized              false
Sealed                   true
Total Recovery Shares    0
Threshold                0
Unseal Progress          0/0
Unseal Nonce             n/a
Version                  n/a
HA Enabled               false
```

Initialize the vault.

```bash
$ vault operator init
Recovery Key 1: ...
Recovery Key 2: ...
Recovery Key 3: ...
Recovery Key 4: ...
Recovery Key 5: ...

Initial Root Token: s....

Success! Vault is initialized

Recovery key initialized with 5 key shares and a key threshold of 3. Please
securely distribute the key shares printed above.
```

From here, Vault is operational. Configure the auth methods needed and other
settings. The Cloud Run Service may scale the container to zero, but the server
configuration and unseal keys are configured. When restarting, the Vault should
unseal itself automatically using the Google KMS. For more information on
deploying Vault, read
[Deploy Vault](https://learn.hashicorp.com/vault/getting-started/deploy).

## Inputs

To configure the module, provide the required variables and any optional variables you wish to use. See the `variables.tf` file for a full list of available variables.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | The ID of the Google Cloud project to deploy resources to. | `string` | n/a | yes |
| location | The region to deploy resources to. | `string` | n/a | yes |
| name | The name of the Vault instance. | `string` | n/a | yes |
| vault_image | The Docker image to use for the Vault server. | `string` | `"us.gcr.io/vault-226618/vault:latest"` | no |
| vault_service_account_id | The ID for the service account to be used. | `string` | `"vault-sa"` | no |
| authorized_ip_ranges | List of authorized IP ranges. | `list(string)` | `[]` | no |
| lb_domains | List of domains for managed SSL certificate. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| status | The current status of the Cloud Run domain mapping. |
| app_url | The URL of the deployed Vault Cloud Run service. |
| service_account_email | The email address of the Vault service account used for KMS auto-unseal. |
| cloud_run_load_balancer_ip | The IP address of the Cloud Run load balancer

## Security Concerns

The following things may be of concern from a security perspective:

- By default, Vault is running on shared compute infrastructure. The [Google Terraform provider](https://github.com/hashicorp/terraform-provider-google) does not yet support Cloud Run on Anthos / GKE to deploy on single-tenant VMs.

## Caveats

### Google Cloud Container Registry

Cloud Run will only run containers hosted on `gcr.io` (GCR) and its subdomains.
This means that the Vault container will need to be pushed to GCR in the Google
Cloud Project. Terraform cannot currently create the container registry and it
is automatically created using `docker push`. Read the
[documentation](https://cloud.google.com/container-registry/docs/pushing-and-pulling)
for more details on pushing containers to GCR.

A quick way to get Vault into GCR for a GCP project:

```bash
gcloud auth configure-docker
docker pull hashicorp/vault:latest
docker tag hashicorp/vault:latest gcr.io/{{ project_id }}/vault:latest
docker push gcr.io/{{ project_id }}/vault:latest
```

## Acknowledgments

This Terraform module is a modified version of the [terraform-google-vault](https://github.com/mbrancato/terraform-google-vault) module created by [Mike Brancato](https://github.com/mbrancato).
