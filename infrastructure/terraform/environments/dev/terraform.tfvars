# =============================================================================
# DEVELOPMENT ENVIRONMENT VALUES
# Specific configuration for the development environment
# =============================================================================

# Key Vault - Initial secrets for microservices
initial_secrets = {}

# Alert emails for budget notifications
alert_emails = ["criedboca@gmail.com"]

# Basic configuration
environment  = "dev"
project_name = "msworkshop1"
location     = "East US"
owner        = "DevOps-Team"

# Networking - Simplified (removed app gateway for cost optimization)
vnet_address_space            = ["10.0.0.0/16"]
aks_subnet_cidr               = "10.0.1.0/24"
# app_gateway_subnet_cidr       = "10.0.2.0/24"  # REMOVED - Use AKS Ingress instead
# private_endpoints_subnet_cidr = "10.0.3.0/24"  # REMOVED - Not needed for dev

# AKS Configuration - Cost Optimized for Development
kubernetes_version      = "1.30.14"
aks_sku_tier            = "Free"
aks_node_count          = 1
aks_vm_size             = "Standard_B2s"
aks_enable_auto_scaling = false
aks_min_count           = null
aks_max_count           = null
aks_use_spot_instances  = true
aks_spot_max_price      = 0.02
aks_max_pods_per_node   = 110
aks_os_disk_size_gb     = 128
aks_max_surge           = "10%"

# Network configuration
aks_network_plugin = "azure"
aks_network_policy = "azure"
aks_dns_service_ip = "10.254.0.10"
aks_service_cidr   = "10.254.0.0/16"

# Azure AD integration (disabled for dev)
aks_enable_azure_ad_integration     = false
aks_azure_ad_admin_group_object_ids = []
aks_azure_rbac_enabled              = false

# ACR Configuration - Basic for cost optimization
acr_sku                           = "Basic"
acr_admin_enabled                 = true
acr_public_network_access_enabled = true
acr_network_rule_bypass_option    = "AzureServices"

# Retention policy for cost optimization
acr_retention_policy = {
  days    = 7
  enabled = true
}

# Key Vault Configuration
key_vault_sku                           = "standard"
key_vault_soft_delete_retention_days    = 7
key_vault_purge_protection_enabled      = false
key_vault_public_network_access_enabled = true

# App Configuration
enable_app_configuration = false
app_config_sku           = "free"

# Sample configuration keys
app_configuration_keys = {
  "app:environment" = {
    label        = "dev"
    value        = "development"
    content_type = "text/plain"
    type         = "kv"
    tags         = {}
  }
  "app:log_level" = {
    label        = "dev"
    value        = "debug"
    content_type = "text/plain"
    type         = "kv"
    tags         = {}
  }
  "redis:max_connections" = {
    label        = "dev"
    value        = "100"
    content_type = "text/plain"
    type         = "kv"
    tags         = {}
  }
}

# Private endpoints REMOVED for dev cost optimization
# enable_private_endpoints = false

# Cost Management
monthly_budget = 10
enable_critical_budget_alert = true

# Auto-shutdown REMOVED for simplicity - use Azure policies instead
# enable_auto_shutdown = true

# Additional tags
additional_tags = {
  "CostCenter"   = "Training"
  "Owner"        = "DevOps-Team"
  "Purpose"      = "Workshop-Demo"
  "AutoShutdown" = "true"
  "Environment"  = "Development"
}
