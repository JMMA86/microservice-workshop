# =============================================================================
# SECURITY MODULE - KEY VAULT AND SECRET MANAGEMENT
# Centralized secret management and security configurations
# =============================================================================

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Azure Key Vault
resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Soft delete configuration
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

  # Network access configuration
  public_network_access_enabled = var.public_network_access_enabled
  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  # Access policies
  dynamic "access_policy" {
    for_each = var.access_policies
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value.object_id

      key_permissions    = access_policy.value.key_permissions
      secret_permissions = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
      storage_permissions = access_policy.value.storage_permissions
    }
  }

  tags = var.tags
}

# Key Vault secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each = nonsensitive(var.secrets)

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id
  content_type = each.value.content_type

  # Expiration date (if specified)
  expiration_date = each.value.expiration_date

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_key_vault.main]
}

# App Configuration for non-secret configurations
resource "azurerm_app_configuration" "main" {
  count               = var.enable_app_configuration ? 1 : 0
  name                = var.app_config_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.app_config_sku

  # Identity configuration
  dynamic "identity" {
    for_each = var.app_config_identity != null ? [var.app_config_identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # Encryption configuration
  dynamic "encryption" {
    for_each = var.app_config_encryption != null ? [var.app_config_encryption] : []
    content {
      key_vault_key_identifier   = encryption.value.key_vault_key_identifier
      identity_client_id         = encryption.value.identity_client_id
    }
  }

  # Replica configuration
  dynamic "replica" {
    for_each = var.app_config_replicas
    content {
      name     = replica.value.name
      location = replica.value.location
    }
  }

  tags = var.tags
}

# App Configuration keys
resource "azurerm_app_configuration_key" "config_keys" {
  for_each = var.enable_app_configuration ? var.app_configuration_keys : {}

  configuration_store_id = azurerm_app_configuration.main[0].id
  key                   = each.key
  label                 = each.value.label
  value                 = each.value.value
  content_type          = each.value.content_type
  type                  = each.value.type

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_app_configuration.main]
}

# Private endpoint for Key Vault (if enabled)
resource "azurerm_private_endpoint" "key_vault" {
  count               = var.enable_key_vault_private_endpoint ? 1 : 0
  name                = "${var.key_vault_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names             = ["vault"]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.key_vault_private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "keyvault-dns-zone-group"
      private_dns_zone_ids = var.key_vault_private_dns_zone_ids
    }
  }

  tags = var.tags
}

# Private endpoint for App Configuration (if enabled)
resource "azurerm_private_endpoint" "app_config" {
  count               = var.enable_app_configuration && var.enable_app_config_private_endpoint ? 1 : 0
  name                = "${var.app_config_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.app_config_name}-psc"
    private_connection_resource_id = azurerm_app_configuration.main[0].id
    subresource_names             = ["configurationStores"]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.app_config_private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "appconfig-dns-zone-group"
      private_dns_zone_ids = var.app_config_private_dns_zone_ids
    }
  }

  tags = var.tags
}

# Role assignments for Key Vault access
resource "azurerm_role_assignment" "key_vault_access" {
  for_each = var.key_vault_role_assignments

  scope                = azurerm_key_vault.main.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# Role assignments for App Configuration access
resource "azurerm_role_assignment" "app_config_access" {
  for_each = var.enable_app_configuration ? var.app_config_role_assignments : {}

  scope                = azurerm_app_configuration.main[0].id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# Key Vault diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count                      = var.enable_key_vault_diagnostics ? 1 : 0
  name                       = "${var.key_vault_name}-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# App Configuration diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "app_config" {
  count                      = var.enable_app_configuration && var.enable_app_config_diagnostics ? 1 : 0
  name                       = "${var.app_config_name}-diagnostics"
  target_resource_id         = azurerm_app_configuration.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "HttpRequest"
  }

  enabled_log {
    category = "Audit"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
