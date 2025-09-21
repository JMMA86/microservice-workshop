# =============================================================================
# SECURITY MODULE VARIABLES
# =============================================================================

variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be 3-24 characters, alphanumeric and hyphens only."
  }
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "SKU for the Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "Number of days for soft delete retention"
  type        = number
  default     = 7
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access to Key Vault"
  type        = bool
  default     = true
}

# Network ACLs
variable "network_acls" {
  description = "Network ACLs for Key Vault"
  type = object({
    default_action             = string
    bypass                     = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = {
    default_action             = "Allow"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

# Access policies
variable "access_policies" {
  description = "Access policies for Key Vault"
  type = map(object({
    object_id                   = string
    key_permissions            = list(string)
    secret_permissions         = list(string)
    certificate_permissions    = list(string)
    storage_permissions        = list(string)
  }))
  default = {}
}

# Secrets
variable "secrets" {
  description = "Secrets to store in Key Vault"
  type = map(object({
    value           = string
    content_type    = string
    expiration_date = string
    tags           = map(string)
  }))
  default   = {}
  sensitive = true
}

# App Configuration
variable "enable_app_configuration" {
  description = "Enable Azure App Configuration"
  type        = bool
  default     = true
}

variable "app_config_name" {
  description = "Name of the Azure App Configuration"
  type        = string
  default     = ""
}

variable "app_config_sku" {
  description = "SKU for Azure App Configuration"
  type        = string
  default     = "free"
  validation {
    condition     = contains(["free", "standard"], var.app_config_sku)
    error_message = "App Config SKU must be 'free' or 'standard'."
  }
}

variable "app_config_identity" {
  description = "Managed identity for App Configuration"
  type = object({
    type         = string
    identity_ids = list(string)
  })
  default = null
}

variable "app_config_encryption" {
  description = "Encryption configuration for App Configuration"
  type = object({
    key_vault_key_identifier = string
    identity_client_id       = string
  })
  default = null
}

variable "app_config_replicas" {
  description = "Replicas for App Configuration"
  type = list(object({
    name     = string
    location = string
  }))
  default = []
}

variable "app_configuration_keys" {
  description = "Configuration keys for App Configuration"
  type = map(object({
    label        = string
    value        = string
    content_type = string
    type         = string
    tags         = map(string)
  }))
  default = {}
}

# Private Endpoints
variable "enable_key_vault_private_endpoint" {
  description = "Enable private endpoint for Key Vault"
  type        = bool
  default     = false
}

variable "enable_app_config_private_endpoint" {
  description = "Enable private endpoint for App Configuration"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = null
}

variable "key_vault_private_dns_zone_ids" {
  description = "Private DNS zone IDs for Key Vault private endpoint"
  type        = list(string)
  default     = []
}

variable "app_config_private_dns_zone_ids" {
  description = "Private DNS zone IDs for App Configuration private endpoint"
  type        = list(string)
  default     = []
}

# Role assignments
variable "key_vault_role_assignments" {
  description = "Role assignments for Key Vault"
  type = map(object({
    role_definition_name = string
    principal_id         = string
  }))
  default = {}
}

variable "app_config_role_assignments" {
  description = "Role assignments for App Configuration"
  type = map(object({
    role_definition_name = string
    principal_id         = string
  }))
  default = {}
}

# Diagnostics
variable "enable_key_vault_diagnostics" {
  description = "Enable diagnostic settings for Key Vault"
  type        = bool
  default     = false
}

variable "enable_app_config_diagnostics" {
  description = "Enable diagnostic settings for App Configuration"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
