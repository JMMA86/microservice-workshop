# =============================================================================
# DEVELOPMENT ENVIRONMENT VARIABLES
# All configurable parameters for the development environment
# =============================================================================

# Basic configuration
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "msworkshop"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps-Team"
}

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_cidr" {
  description = "CIDR block for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "app_gateway_subnet_cidr" {
  description = "CIDR block for Application Gateway subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_endpoints_subnet_cidr" {
  description = "CIDR block for Private Endpoints subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# =============================================================================
# AKS CONFIGURATION
# =============================================================================

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.27"
}

variable "aks_sku_tier" {
  description = "SKU tier for AKS cluster"
  type        = string
  default     = "Free"
}

variable "aks_node_count" {
  description = "Initial number of nodes in AKS cluster"
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "aks_enable_auto_scaling" {
  description = "Enable auto-scaling for AKS"
  type        = bool
  default     = true
}

variable "aks_min_count" {
  description = "Minimum number of nodes for auto-scaling"
  type        = number
  default     = 1
}

variable "aks_max_count" {
  description = "Maximum number of nodes for auto-scaling"
  type        = number
  default     = 3
}

variable "aks_use_spot_instances" {
  description = "Use spot instances for cost optimization"
  type        = bool
  default     = true
}

variable "aks_spot_max_price" {
  description = "Maximum price for spot instances"
  type        = number
  default     = 0.01
}

variable "aks_max_pods_per_node" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 110
}

variable "aks_os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "aks_max_surge" {
  description = "Maximum surge for node upgrades"
  type        = string
  default     = "10%"
}

# Network configuration for AKS
variable "aks_network_plugin" {
  description = "Network plugin for AKS"
  type        = string
  default     = "azure"
}

variable "aks_network_policy" {
  description = "Network policy for AKS"
  type        = string
  default     = "azure"
}

variable "aks_dns_service_ip" {
  description = "DNS service IP for AKS"
  type        = string
  default     = "10.254.0.10"
}

variable "aks_service_cidr" {
  description = "Service CIDR for AKS"
  type        = string
  default     = "10.254.0.0/16"
}

# Auto-scaler profile
variable "aks_auto_scaler_profile" {
  description = "Auto-scaler profile configuration"
  type = object({
    balance_similar_node_groups      = bool
    expander                         = string
    max_graceful_termination_sec     = string
    max_node_provisioning_time       = string
    max_unready_nodes                = number
    max_unready_percentage           = number
    new_pod_scale_up_delay           = string
    scale_down_delay_after_add       = string
    scale_down_delay_after_delete    = string
    scale_down_delay_after_failure   = string
    scan_interval                    = string
    scale_down_unneeded              = string
    scale_down_unready               = string
    scale_down_utilization_threshold = number
  })
  default = {
    balance_similar_node_groups      = false
    expander                         = "random"
    max_graceful_termination_sec     = "600"
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = 0.5
  }
}

# Azure AD integration
variable "aks_enable_azure_ad_integration" {
  description = "Enable Azure AD integration for AKS"
  type        = bool
  default     = false
}

variable "aks_azure_ad_admin_group_object_ids" {
  description = "Azure AD admin group object IDs"
  type        = list(string)
  default     = []
}

variable "aks_azure_rbac_enabled" {
  description = "Enable Azure RBAC for AKS"
  type        = bool
  default     = false
}

# Additional node pools
variable "aks_additional_node_pools" {
  description = "Additional node pools for AKS"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    use_spot_instances  = bool
    spot_max_price      = number
    max_pods_per_node   = number
    os_disk_size_gb     = number
    os_type             = string
    node_labels         = map(string)
    node_taints         = list(string)
  }))
  default = {}
}

# Maintenance window
variable "aks_maintenance_window" {
  description = "Maintenance window for AKS"
  type = object({
    allowed = list(object({
      day   = string
      hours = list(number)
    }))
    not_allowed = list(object({
      end   = string
      start = string
    }))
  })
  default = null
}

# =============================================================================
# ACR CONFIGURATION
# =============================================================================

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "acr_admin_enabled" {
  description = "Enable admin user for ACR"
  type        = bool
  default     = true
}

variable "acr_public_network_access_enabled" {
  description = "Enable public network access for ACR"
  type        = bool
  default     = true
}

variable "acr_network_rule_bypass_option" {
  description = "Network rule bypass option for ACR"
  type        = string
  default     = "AzureServices"
}

variable "acr_retention_policy" {
  description = "Retention policy for ACR"
  type = object({
    days    = number
    enabled = bool
  })
  default = {
    days    = 7
    enabled = true
  }
}

variable "acr_webhooks" {
  description = "Webhooks for ACR"
  type = map(object({
    service_uri    = string
    status         = string
    scope          = string
    actions        = list(string)
    custom_headers = map(string)
  }))
  default = {}
}

# =============================================================================
# KEY VAULT CONFIGURATION
# =============================================================================

variable "key_vault_sku" {
  description = "SKU for Key Vault"
  type        = string
  default     = "standard"
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention days for Key Vault"
  type        = number
  default     = 7
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

variable "key_vault_public_network_access_enabled" {
  description = "Enable public network access for Key Vault"
  type        = bool
  default     = true
}

variable "key_vault_network_acls" {
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

variable "key_vault_access_policies" {
  description = "Access policies for Key Vault"
  type = map(object({
    object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
    storage_permissions     = list(string)
  }))
  default = {}
}

variable "initial_secrets" {
  description = "Initial secrets to store in Key Vault"
  type = map(object({
    value           = string
    content_type    = string
    expiration_date = string
    tags            = map(string)
  }))
  default   = {}
  sensitive = true
}

# =============================================================================
# APP CONFIGURATION
# =============================================================================

variable "enable_app_configuration" {
  description = "Enable Azure App Configuration"
  type        = bool
  default     = true
}

variable "app_config_sku" {
  description = "SKU for App Configuration"
  type        = string
  default     = "free"
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

# =============================================================================
# PRIVATE ENDPOINTS
# =============================================================================

variable "enable_private_endpoints" {
  description = "Enable private endpoints for enhanced security"
  type        = bool
  default     = false
}

# =============================================================================
# COST MANAGEMENT
# =============================================================================

variable "monthly_budget" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 10
}

variable "alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
}

variable "enable_critical_budget_alert" {
  description = "Enable critical budget alert at 120%"
  type        = bool
  default     = true
}

# =============================================================================
# AUTO-SHUTDOWN
# =============================================================================

variable "enable_auto_shutdown" {
  description = "Enable auto-shutdown for cost optimization"
  type        = bool
  default     = true
}

# =============================================================================
# TAGS
# =============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
