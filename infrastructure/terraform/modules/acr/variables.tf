# =============================================================================
# ACR MODULE VARIABLES
# =============================================================================

variable "registry_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.registry_name)) && length(var.registry_name) >= 5 && length(var.registry_name) <= 50
    error_message = "Registry name must be alphanumeric and between 5-50 characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the ACR"
  type        = string
}

variable "sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for the registry"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "network_rule_bypass_option" {
  description = "Network rule bypass option"
  type        = string
  default     = "AzureServices"
  validation {
    condition     = contains(["AzureServices", "None"], var.network_rule_bypass_option)
    error_message = "Network rule bypass option must be AzureServices or None."
  }
}

# Retention policy
variable "retention_policy" {
  description = "Retention policy for images"
  type = object({
    days    = number
    enabled = bool
  })
  default = null
}

# Trust policy
variable "trust_policy" {
  description = "Trust policy configuration"
  type = object({
    enabled = bool
  })
  default = null
}

# Network rules
variable "network_rule_set" {
  description = "Network rule set for ACR"
  type = object({
    default_action = string
    ip_rules = list(object({
      action   = string
      ip_range = string
    }))
    virtual_networks = list(object({
      action    = string
      subnet_id = string
    }))
  })
  default = null
}

# Encryption
variable "encryption" {
  description = "Encryption configuration"
  type = object({
    enabled            = bool
    key_vault_key_id   = string
    identity_client_id = string
  })
  default = null
}

# Georeplications
variable "georeplications" {
  description = "Georeplications for the registry"
  type = list(object({
    location                  = string
    regional_endpoint_enabled = bool
    zone_redundancy_enabled   = bool
    tags                     = map(string)
  }))
  default = []
}

# AKS integration
variable "aks_principal_id" {
  description = "Principal ID of the AKS cluster for ACR integration"
  type        = string
  default     = null
}

# Additional role assignments
variable "additional_role_assignments" {
  description = "Additional role assignments for the ACR"
  type = map(object({
    role_definition_name = string
    principal_id         = string
  }))
  default = {}
}

# Private endpoint
variable "enable_private_endpoint" {
  description = "Enable private endpoint for ACR"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Private DNS zone IDs for private endpoint"
  type        = list(string)
  default     = []
}

# Webhooks
variable "webhooks" {
  description = "Webhooks configuration for CI/CD integration"
  type = map(object({
    service_uri    = string
    status         = string
    scope          = string
    actions        = list(string)
    custom_headers = map(string)
  }))
  default = {}
}

# Build tasks
variable "build_tasks" {
  description = "Container registry build tasks"
  type = map(object({
    platform = object({
      os           = string
      architecture = string
      variant      = string
    })
    docker_step = object({
      dockerfile_path      = string
      context_path        = string
      context_access_token = string
      image_names         = list(string)
    })
    source_triggers = list(object({
      name           = string
      repository_url = string
      source_type    = string
      branch         = string
      events         = list(string)
      authentication = object({
        token      = string
        token_type = string
      })
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
