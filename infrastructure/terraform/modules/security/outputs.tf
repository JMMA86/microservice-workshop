# =============================================================================
# SECURITY MODULE OUTPUTS
# =============================================================================

# Key Vault outputs
output "key_vault_id" {
  description = "ID of the Azure Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_tenant_id" {
  description = "Tenant ID of the Azure Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}

# App Configuration outputs
output "app_config_id" {
  description = "ID of the Azure App Configuration"
  value       = var.enable_app_configuration ? azurerm_app_configuration.main[0].id : null
}

output "app_config_name" {
  description = "Name of the Azure App Configuration"
  value       = var.enable_app_configuration ? azurerm_app_configuration.main[0].name : null
}

output "app_config_endpoint" {
  description = "Endpoint of the Azure App Configuration"
  value       = var.enable_app_configuration ? azurerm_app_configuration.main[0].endpoint : null
}

output "app_config_primary_read_key" {
  description = "Primary read key for App Configuration"
  value       = var.enable_app_configuration ? azurerm_app_configuration.main[0].primary_read_key : null
  sensitive   = true
}

output "app_config_primary_write_key" {
  description = "Primary write key for App Configuration"
  value       = var.enable_app_configuration ? azurerm_app_configuration.main[0].primary_write_key : null
  sensitive   = true
}

output "app_config_secondary_read_key" {
  description = "Secondary read key for App Configuration"
  value       = var.enable_app_configuration ? azurerm_app_configuration.main[0].secondary_read_key : null
  sensitive   = true
}

output "app_config_secondary_write_key" {
  description = "Secondary write key for App Configuration"
  value       = var.enable_app_configuration ? azurerm_app_configuration.main[0].secondary_write_key : null
  sensitive   = true
}

# Secret outputs (metadata only, not values for security)
output "secret_names" {
  description = "Names of secrets stored in Key Vault"
  value       = keys(var.secrets)
}

output "secret_versions" {
  description = "Versions of secrets in Key Vault"
  value = {
    for name, secret in azurerm_key_vault_secret.secrets : name => secret.version
  }
}

# Configuration key outputs
output "app_config_key_names" {
  description = "Names of configuration keys in App Configuration"
  value       = var.enable_app_configuration ? keys(var.app_configuration_keys) : []
}

# Private endpoint outputs
output "key_vault_private_endpoint_id" {
  description = "ID of the Key Vault private endpoint"
  value       = var.enable_key_vault_private_endpoint ? azurerm_private_endpoint.key_vault[0].id : null
}

output "key_vault_private_endpoint_ip" {
  description = "Private IP address of the Key Vault private endpoint"
  value       = var.enable_key_vault_private_endpoint ? azurerm_private_endpoint.key_vault[0].private_service_connection[0].private_ip_address : null
}

output "app_config_private_endpoint_id" {
  description = "ID of the App Configuration private endpoint"
  value       = var.enable_app_configuration && var.enable_app_config_private_endpoint ? azurerm_private_endpoint.app_config[0].id : null
}

output "app_config_private_endpoint_ip" {
  description = "Private IP address of the App Configuration private endpoint"
  value       = var.enable_app_configuration && var.enable_app_config_private_endpoint ? azurerm_private_endpoint.app_config[0].private_service_connection[0].private_ip_address : null
}

# Access information
output "key_vault_access_policies_count" {
  description = "Number of access policies configured"
  value       = length(var.access_policies)
}

output "key_vault_role_assignments_count" {
  description = "Number of role assignments configured for Key Vault"
  value       = length(var.key_vault_role_assignments)
}

output "app_config_role_assignments_count" {
  description = "Number of role assignments configured for App Configuration"
  value       = length(var.app_config_role_assignments)
}

# Diagnostic settings
output "key_vault_diagnostics_enabled" {
  description = "Whether diagnostics are enabled for Key Vault"
  value       = var.enable_key_vault_diagnostics
}

output "app_config_diagnostics_enabled" {
  description = "Whether diagnostics are enabled for App Configuration"
  value       = var.enable_app_config_diagnostics
}

# Security configuration summary
output "security_summary" {
  description = "Summary of security configuration"
  value = {
    key_vault = {
      name                         = azurerm_key_vault.main.name
      sku                         = azurerm_key_vault.main.sku_name
      soft_delete_retention_days  = azurerm_key_vault.main.soft_delete_retention_days
      purge_protection_enabled    = azurerm_key_vault.main.purge_protection_enabled
      public_network_access_enabled = azurerm_key_vault.main.public_network_access_enabled
      private_endpoint_enabled    = var.enable_key_vault_private_endpoint
      secrets_count              = length(var.secrets)
      access_policies_count      = length(var.access_policies)
    }
    app_configuration = var.enable_app_configuration ? {
      name                    = azurerm_app_configuration.main[0].name
      sku                    = azurerm_app_configuration.main[0].sku
      private_endpoint_enabled = var.enable_app_config_private_endpoint
      keys_count             = length(var.app_configuration_keys)
    } : null
  }
}
