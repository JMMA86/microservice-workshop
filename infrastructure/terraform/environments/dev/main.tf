# =============================================================================
# DEVELOPMENT ENVIRONMENT - MAIN CONFIGURATION
# Uses modular approach for infrastructure deployment
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

}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Local values for consistent naming and tagging
locals {
  environment     = var.environment
  project_name    = var.project_name
  location        = var.location

  # Naming convention
  naming_prefix = "${local.project_name}-${local.environment}"

  # Common tags
  common_tags = merge(var.additional_tags, {
    Environment  = local.environment
    Project      = local.project_name
    CreatedBy    = "Terraform"
    Purpose      = "DevOps-Training"
    CostCenter   = "Training"
    AutoShutdown = "true"
    Owner        = var.owner
    ManagedBy    = "Infrastructure-Team"
  })
}

# =============================================================================
# RESOURCE GROUP
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = "${local.naming_prefix}-rg"
  location = local.location
  tags     = local.common_tags
}

# =============================================================================
# NETWORKING MODULE
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  vnet_name           = "${local.naming_prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_prefix       = "${local.naming_prefix}"

  # Subnet configuration - Simplified for cost optimization
  aks_subnet_cidr     = var.aks_subnet_cidr
  tags                = local.common_tags
}

# =============================================================================
# SECURITY MODULE (KEY VAULT + APP CONFIG)
# =============================================================================
module "security" {
  source = "../../modules/security"

  key_vault_name      = "${local.project_name}${local.environment}kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = var.key_vault_sku

  # Key Vault configuration
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  public_network_access_enabled = var.key_vault_public_network_access_enabled

  # Network ACLs
  network_acls = {
    default_action             = var.key_vault_network_acls.default_action
    bypass                     = var.key_vault_network_acls.bypass
    ip_rules                   = var.key_vault_network_acls.ip_rules
    virtual_network_subnet_ids = var.key_vault_network_acls.virtual_network_subnet_ids
  }

  # Access policies - Include current user automatically
  access_policies = merge(var.key_vault_access_policies, {
    current_user = {
      object_id = data.azurerm_client_config.current.object_id
      key_permissions = [
        "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore"
      ]
      secret_permissions = [
        "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
      ]
      certificate_permissions = [
        "Get", "List", "Create", "Delete", "Recover", "ManageContacts", "ManageIssuers"
      ]
      storage_permissions = [
        "Get", "List", "Set", "Delete"
      ]
    }
  })

  # Secrets (will be added after AKS creation for service principal secrets)
  secrets = var.initial_secrets

  # App Configuration
  enable_app_configuration = var.enable_app_configuration
  app_config_name          = "${local.project_name}${local.environment}config"
  app_config_sku           = var.app_config_sku
  app_configuration_keys   = var.app_configuration_keys

  tags = local.common_tags

  depends_on = [module.networking]
}

# =============================================================================
# AZURE CONTAINER REGISTRY MODULE
# =============================================================================
module "acr" {
  source = "../../modules/acr"

  registry_name       = "${local.project_name}${local.environment}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled

  # Network configuration
  public_network_access_enabled = var.acr_public_network_access_enabled
  network_rule_bypass_option    = var.acr_network_rule_bypass_option

  # Cost optimization policies
  retention_policy = var.acr_retention_policy

  tags = local.common_tags

  depends_on = [module.networking]
}

# =============================================================================
# AZURE KUBERNETES SERVICE MODULE
# =============================================================================
module "aks" {
  source = "../../modules/aks"

  cluster_name        = "${local.naming_prefix}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${local.naming_prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.aks_sku_tier

  # Node pool configuration
  node_count          = var.aks_node_count
  vm_size             = var.aks_vm_size
  enable_auto_scaling = var.aks_enable_auto_scaling
  min_count           = var.aks_min_count
  max_count           = var.aks_max_count

  # Cost optimization
  use_spot_instances = var.aks_use_spot_instances
  spot_max_price     = var.aks_spot_max_price

  # Node configuration
  max_pods_per_node = var.aks_max_pods_per_node
  os_disk_size_gb   = var.aks_os_disk_size_gb
  max_surge         = var.aks_max_surge

  # Network configuration
  subnet_id      = module.networking.aks_subnet_id
  network_plugin = var.aks_network_plugin
  network_policy = var.aks_network_policy
  dns_service_ip = var.aks_dns_service_ip
  service_cidr   = var.aks_service_cidr

  # Auto-scaler profile for cost optimization
  auto_scaler_profile = var.aks_auto_scaler_profile

  # Azure AD integration (disabled for dev environment)
  enable_azure_ad_integration     = var.aks_enable_azure_ad_integration
  azure_ad_admin_group_object_ids = var.aks_azure_ad_admin_group_object_ids
  azure_rbac_enabled              = var.aks_azure_rbac_enabled

  # Additional node pools
  additional_node_pools = var.aks_additional_node_pools

  # Maintenance window
  maintenance_window = var.aks_maintenance_window

  tags = local.common_tags

  depends_on = [module.networking, module.acr]
}

provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.kube_config[0].client_certificate)
  client_key             = base64decode(module.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes =  {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.kube_config[0].client_certificate)
    client_key             = base64decode(module.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config[0].cluster_ca_certificate)
  }
}

# =============================================================================
# ACR-AKS INTEGRATION
# =============================================================================
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity.object_id
}

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.10.0"

  create_namespace = true

  set = [{
    name  = "controller.publishService.enabled"
    value = "true"
  }]

  depends_on = [module.aks]
}

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.nginx_ingress]
}

output "INGRESS_PUBLIC_IP" {
  description = "IP pública del servicio ingress-nginx-controller"
  value       = try(data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].ip, null)
}

# =============================================================================
# BUDGET AND COST MANAGEMENT
# =============================================================================
resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "${local.naming_prefix}-budget"
  resource_group_id = azurerm_resource_group.main.id

  amount     = var.monthly_budget
  time_grain = "Monthly"

  time_period {
    start_date = "2025-09-01T00:00:00Z"
    end_date   = "2025-09-30T23:59:59Z"
  }

  notification {
    enabled   = true
    threshold = 60
    operator  = "GreaterThan"

    contact_emails = var.alert_emails
  }

  notification {
    enabled   = true
    threshold = 80
    operator  = "GreaterThan"

    contact_emails = var.alert_emails
  }

  dynamic "notification" {
    for_each = var.enable_critical_budget_alert ? [1] : []
    content {
      enabled   = true
      threshold = 90
      operator  = "GreaterThan"

      contact_emails = var.alert_emails
    }
  }
}
