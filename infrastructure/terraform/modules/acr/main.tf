# =============================================================================
# ACR MODULE - AZURE CONTAINER REGISTRY
# Private container registry with security and cost optimization
# =============================================================================

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # Public network access configuration
  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = var.network_rule_bypass_option

  # Retention policy for cost optimization (only available for Premium SKU)
  dynamic "retention_policy" {
    for_each = var.retention_policy != null && var.sku == "Premium" ? [var.retention_policy] : []
    content {
      days    = retention_policy.value.days
      enabled = retention_policy.value.enabled
    }
  }

  # Trust policy
  dynamic "trust_policy" {
    for_each = var.trust_policy != null ? [var.trust_policy] : []
    content {
      enabled = trust_policy.value.enabled
    }
  }

  # Network rules for enhanced security
  dynamic "network_rule_set" {
    for_each = var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules
        content {
          action   = ip_rule.value.action
          ip_range = ip_rule.value.ip_range
        }
      }

      dynamic "virtual_network" {
        for_each = network_rule_set.value.virtual_networks
        content {
          action    = virtual_network.value.action
          subnet_id = virtual_network.value.subnet_id
        }
      }
    }
  }

  # Encryption configuration
  dynamic "encryption" {
    for_each = var.encryption != null ? [var.encryption] : []
    content {
      enabled            = encryption.value.enabled
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  # Georeplications for multi-region (Premium SKU only)
  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags                     = merge(var.tags, georeplications.value.tags)
    }
  }

  tags = var.tags
}

# Role assignment for AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.aks_principal_id != null ? 1 : 0
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_principal_id
}

# Additional role assignments
resource "azurerm_role_assignment" "additional" {
  for_each = var.additional_role_assignments

  scope                = azurerm_container_registry.main.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# Private endpoint for ACR (if enabled)
resource "azurerm_private_endpoint" "acr" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.registry_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.registry_name}-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names             = ["registry"]
    is_manual_connection          = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

# Webhook for CI/CD integration (if enabled)
resource "azurerm_container_registry_webhook" "webhook" {
  for_each = var.webhooks

  name                = each.key
  resource_group_name = var.resource_group_name
  registry_name       = azurerm_container_registry.main.name
  location            = var.location

  service_uri = each.value.service_uri
  status      = each.value.status
  scope       = each.value.scope
  actions     = each.value.actions

  custom_headers = each.value.custom_headers

  tags = var.tags
}

# Task for automated image builds (Premium SKU only)
resource "azurerm_container_registry_task" "build_task" {
  for_each = var.build_tasks

  name                  = each.key
  container_registry_id = azurerm_container_registry.main.id
  
  platform {
    os           = each.value.platform.os
    architecture = each.value.platform.architecture
    variant      = each.value.platform.variant
  }

  docker_step {
    dockerfile_path      = each.value.docker_step.dockerfile_path
    context_path        = each.value.docker_step.context_path
    context_access_token = each.value.docker_step.context_access_token
    image_names         = each.value.docker_step.image_names
  }

  dynamic "source_trigger" {
    for_each = each.value.source_triggers
    content {
      name           = source_trigger.value.name
      repository_url = source_trigger.value.repository_url
      source_type   = source_trigger.value.source_type
      branch        = source_trigger.value.branch
      events        = source_trigger.value.events

      dynamic "authentication" {
        for_each = source_trigger.value.authentication != null ? [source_trigger.value.authentication] : []
        content {
          token      = authentication.value.token
          token_type = authentication.value.token_type
        }
      }
    }
  }

  tags = var.tags
}
