# =============================================================================
# TERRAFORM BACKEND BOOTSTRAP
# Creates the Azure Storage Account for remote state management
# This runs ONCE with local state, then we migrate to remote state
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  # NO backend block - this uses local state to create the backend infrastructure
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Random suffix for unique storage account name
resource "random_id" "storage_suffix" {
  byte_length = 4
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Resource group for Terraform state
resource "azurerm_resource_group" "tfstate" {
  name     = "terraform-state-rg"
  location = var.location
  
  tags = {
    Purpose     = "Terraform-State"
    Environment = "shared"
    CreatedBy   = "Terraform-Bootstrap"
    Project     = "microservices-workshop"
  }
}

# Storage account for Terraform state
resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Enable versioning for state file protection
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }
  
  tags = {
    Purpose     = "Terraform-State"
    Environment = "shared"
    CreatedBy   = "Terraform-Bootstrap"
    Project     = "microservices-workshop"
  }
}

# Container for Terraform state files
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Additional containers for different environments
resource "azurerm_storage_container" "tfstate_dev" {
  name                  = "tfstate-dev"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "tfstate_staging" {
  name                  = "tfstate-staging"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "tfstate_prod" {
  name                  = "tfstate-prod"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Key Vault for storing sensitive backend information (optional)
resource "azurerm_key_vault" "tfstate" {
  name                = "tfstate-kv-${random_id.storage_suffix.hex}"
  location            = azurerm_resource_group.tfstate.location
  resource_group_name = azurerm_resource_group.tfstate.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
    ]
  }

  tags = {
    Purpose     = "Terraform-State-Secrets"
    Environment = "shared"
    CreatedBy   = "Terraform-Bootstrap"
    Project     = "microservices-workshop"
  }
}

# Store storage account key in Key Vault
resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "terraform-backend-storage-key"
  value        = azurerm_storage_account.tfstate.primary_access_key
  key_vault_id = azurerm_key_vault.tfstate.id
  
  tags = {
    Purpose = "Terraform-Backend-Access"
  }
}

# Store storage account name in Key Vault
resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "terraform-backend-storage-name"
  value        = azurerm_storage_account.tfstate.name
  key_vault_id = azurerm_key_vault.tfstate.id
  
  tags = {
    Purpose = "Terraform-Backend-Access"
  }
}
