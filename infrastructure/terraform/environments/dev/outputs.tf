# =============================================================================
# DEVELOPMENT ENVIRONMENT OUTPUTS
# All outputs from the development infrastructure
# =============================================================================

# Generate backend-config.hcl for DEV environment
resource "local_file" "aks_acr_config_dev" {
  content = <<-EOT
# =============================================================================
# AKS and ACR Configuration File - DEV Environment
# Generated automatically by dev environment
# =============================================================================
aks_cluster_name = "${module.aks.cluster_name}"
acr_registry_name = "${module.acr.registry_name}"
# =============================================================================
# USAGE:
# Use these values in your deployment scripts or CI/CD pipelines
# =============================================================================
EOT
  filename = "./aks-acr-config.cfg"
}

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# Networking - Simplified for cost optimization
output "networking" {
  description = "Networking configuration details"
  value = {
    vnet_id         = module.networking.vnet_id
    vnet_name       = module.networking.vnet_name
    aks_subnet_id   = module.networking.aks_subnet_id
    aks_subnet_name = module.networking.aks_subnet_name
    # app_gateway_subnet resources removed for cost optimization
    # private_endpoints_subnet resources removed for cost optimization
  }
}

# AKS Cluster
output "aks" {
  description = "AKS cluster information"
  value = {
    cluster_id             = module.aks.cluster_id
    cluster_name           = module.aks.cluster_name
    cluster_fqdn           = module.aks.cluster_fqdn
    node_resource_group    = module.aks.node_resource_group
    oidc_issuer_url        = module.aks.oidc_issuer_url
    kubectl_config_command = module.aks.kubectl_config_command
  }
  sensitive = true
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_resource_group" {
  description = "Resource group containing AKS cluster"
  value       = azurerm_resource_group.main.name
}

# Azure Container Registry
output "acr" {
  description = "Azure Container Registry information"
  value = {
    registry_id          = module.acr.registry_id
    registry_name        = module.acr.registry_name
    login_server         = module.acr.login_server
    docker_login_command = module.acr.docker_login_command
  }
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = module.acr.login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.acr.registry_name
}

# Security (Key Vault & App Configuration)
output "security" {
  description = "Security configuration details"
  value = {
    key_vault_id        = module.security.key_vault_id
    key_vault_name      = module.security.key_vault_name
    key_vault_uri       = module.security.key_vault_uri
    app_config_id       = module.security.app_config_id
    app_config_name     = module.security.app_config_name
    app_config_endpoint = module.security.app_config_endpoint
  }
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.security.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.security.key_vault_uri
}

# Budget and Cost Management
output "budget" {
  description = "Budget configuration details"
  value = {
    budget_name   = azurerm_consumption_budget_resource_group.main.name
    budget_amount = azurerm_consumption_budget_resource_group.main.amount
    budget_scope  = azurerm_consumption_budget_resource_group.main.resource_group_id
  }
}



# Connection Commands
output "connection_commands" {
  description = "Commands to connect to services"
  value = {
    kubectl_config = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
    docker_login   = "az acr login --name ${module.acr.registry_name}"
    azure_login    = "az login"
  }
}

# Environment Summary
output "environment_summary" {
  description = "Summary of the deployed environment"
  value = {
    environment               = var.environment
    project_name              = var.project_name
    location                  = var.location
    resource_group            = azurerm_resource_group.main.name
    aks_cluster               = module.aks.cluster_name
    acr_registry              = module.acr.registry_name
    key_vault                 = module.security.key_vault_name
    monthly_budget            = var.monthly_budget
    auto_shutdown_enabled     = false  
    private_endpoints_enabled = false  
    cost_optimization = {
      aks_sku_tier       = var.aks_sku_tier
      aks_spot_instances = var.aks_use_spot_instances
      acr_sku            = var.acr_sku
      key_vault_sku      = var.key_vault_sku
      app_config_sku     = var.app_config_sku
    }
  }
}

# Sensitive outputs (use with caution)
output "kube_config" {
  description = "Kubernetes configuration"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "acr_admin_credentials" {
  description = "ACR admin credentials"
  value = {
    username = module.acr.admin_username
    password = module.acr.admin_password
  }
  sensitive = true
}

# Next Steps
output "next_steps" {
  description = "Next steps for deployment"
  value = {
    "1_connect_kubectl" = "Run: az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
    "2_verify_cluster"  = "Run: kubectl cluster-info"
    "3_login_acr"       = "Run: az acr login --name ${module.acr.registry_name}"
    "4_view_secrets"    = "Run: az keyvault secret list --vault-name ${module.security.key_vault_name}"
    "5_check_budget"    = "Monitor costs in Azure portal under Cost Management"
  }
}