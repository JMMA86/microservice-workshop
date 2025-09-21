# =============================================================================
# BOOTSTRAP OUTPUTS
# Information needed to configure backend in other environments
# =============================================================================

output "backend_config" {
  description = "Backend configuration for copy-paste into environment configs"
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    access_key          = azurerm_storage_account.tfstate.primary_access_key
  }
  sensitive = true
}

output "backend_terraform_block" {
  description = "Ready-to-use Terraform backend block"
  value = <<-EOT
terraform {
  backend "azurerm" {
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                 = "ENVIRONMENT_NAME/terraform.tfstate"
  }
}
EOT
}

output "environment_variables" {
  description = "Environment variables for accessing the backend"
  value = <<-EOT
# Add these to your .env file:
export ARM_ACCESS_KEY="${azurerm_storage_account.tfstate.primary_access_key}"

# For CI/CD, you can also use:
# ARM_ACCESS_KEY (sensitive)
# Or configure service principal with Storage Blob Data Contributor role
EOT
  sensitive = true
}

output "storage_account_details" {
  description = "Storage account details for backend configuration"
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    primary_endpoint     = azurerm_storage_account.tfstate.primary_blob_endpoint
    key_vault_name      = azurerm_key_vault.tfstate.name
  }
}

output "containers_created" {
  description = "List of containers created for different environments"
  value = {
    main    = azurerm_storage_container.tfstate.name
    dev     = azurerm_storage_container.tfstate_dev.name
    staging = azurerm_storage_container.tfstate_staging.name
    prod    = azurerm_storage_container.tfstate_prod.name
  }
}

# =============================================================================
# AUTO-GENERATED CONFIGURATION FILES
# These local_file resources automatically generate backend configurations
# =============================================================================

# Generate backend-config.hcl for DEV environment
resource "local_file" "backend_config_dev" {
  content = <<-EOT
# =============================================================================
# TERRAFORM BACKEND CONFIGURATION FILE - DEV ENVIRONMENT
# Generated automatically by bootstrap process
# =============================================================================

resource_group_name  = "${azurerm_resource_group.tfstate.name}"
storage_account_name = "${azurerm_storage_account.tfstate.name}"
container_name       = "${azurerm_storage_container.tfstate_dev.name}"
key                 = "dev/terraform.tfstate"

# Access key - use environment variable ARM_ACCESS_KEY instead for security
# access_key = "YOUR_ACCESS_KEY_HERE"

# =============================================================================
# USAGE:
# terraform init -backend-config="backend-config.hcl"
# =============================================================================
EOT
  filename = "../environments/dev/backend-config.hcl"
}

# Generate backend-config.hcl for STAGING environment
resource "local_file" "backend_config_staging" {
  content = <<-EOT
# =============================================================================
# TERRAFORM BACKEND CONFIGURATION FILE - STAGING ENVIRONMENT
# Generated automatically by bootstrap process
# =============================================================================

resource_group_name  = "${azurerm_resource_group.tfstate.name}"
storage_account_name = "${azurerm_storage_account.tfstate.name}"
container_name       = "${azurerm_storage_container.tfstate_staging.name}"
key                 = "staging/terraform.tfstate"

# Access key - use environment variable ARM_ACCESS_KEY instead for security
# access_key = "YOUR_ACCESS_KEY_HERE"

# =============================================================================
# USAGE:
# terraform init -backend-config="backend-config.hcl"
# =============================================================================
EOT
  filename = "../environments/staging/backend-config.hcl"
}

# Generate backend-config.hcl for PROD environment
resource "local_file" "backend_config_prod" {
  content = <<-EOT
# =============================================================================
# TERRAFORM BACKEND CONFIGURATION FILE - PRODUCTION ENVIRONMENT
# Generated automatically by bootstrap process
# =============================================================================

resource_group_name  = "${azurerm_resource_group.tfstate.name}"
storage_account_name = "${azurerm_storage_account.tfstate.name}"
container_name       = "${azurerm_storage_container.tfstate_prod.name}"
key                 = "prod/terraform.tfstate"

# Access key - use environment variable ARM_ACCESS_KEY instead for security
# access_key = "YOUR_ACCESS_KEY_HERE"

# =============================================================================
# USAGE:
# terraform init -backend-config="backend-config.hcl"
# =============================================================================
EOT
  filename = "../environments/prod/backend-config.hcl"
}