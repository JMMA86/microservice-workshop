# =============================================================================
# AKS MODULE - AZURE KUBERNETES SERVICE
# Cost-optimized AKS cluster with auto-scaling and spot instances
# =============================================================================

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # Cost optimization: Free tier for non-production
  sku_tier = var.sku_tier

  # Default node pool
  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
    
    # Auto-scaling configuration
    enable_auto_scaling = var.enable_auto_scaling
    min_count          = var.min_count
    max_count          = var.max_count
    
    # Node configuration
    max_pods                = var.max_pods_per_node
    os_disk_size_gb        = var.os_disk_size_gb
    os_disk_type           = "Managed"
    temporary_name_for_rotation = "defaulttemp"
    
    # Network configuration
    vnet_subnet_id = var.subnet_id
    
    # Upgrade settings
    upgrade_settings {
      max_surge = var.max_surge
    }

    # Node labels
    node_labels = var.node_labels

    # Node taints (deprecated in v4.0 - use default_node_pool.node_taints instead)
    # node_taints = var.node_taints

    tags = var.tags
  }

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Network profile
  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    dns_service_ip     = var.dns_service_ip
    service_cidr       = var.service_cidr
    load_balancer_sku  = "standard"
  }

  # Azure Monitor integration
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Auto-scaler profile for cost optimization
  auto_scaler_profile {
    balance_similar_node_groups      = var.auto_scaler_profile.balance_similar_node_groups
    expander                        = var.auto_scaler_profile.expander
    max_graceful_termination_sec    = var.auto_scaler_profile.max_graceful_termination_sec
    max_node_provisioning_time      = var.auto_scaler_profile.max_node_provisioning_time
    max_unready_nodes              = var.auto_scaler_profile.max_unready_nodes
    max_unready_percentage         = var.auto_scaler_profile.max_unready_percentage
    new_pod_scale_up_delay         = var.auto_scaler_profile.new_pod_scale_up_delay
    scale_down_delay_after_add     = var.auto_scaler_profile.scale_down_delay_after_add
    scale_down_delay_after_delete  = var.auto_scaler_profile.scale_down_delay_after_delete
    scale_down_delay_after_failure = var.auto_scaler_profile.scale_down_delay_after_failure
    scan_interval                  = var.auto_scaler_profile.scan_interval
    scale_down_unneeded           = var.auto_scaler_profile.scale_down_unneeded
    scale_down_unready            = var.auto_scaler_profile.scale_down_unready
    scale_down_utilization_threshold = var.auto_scaler_profile.scale_down_utilization_threshold
  }

  # RBAC configuration
  role_based_access_control_enabled = true

  # Azure AD integration (optional)
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_integration ? [1] : []
    content {
      managed                = true
      admin_group_object_ids = var.azure_ad_admin_group_object_ids
      azure_rbac_enabled     = var.azure_rbac_enabled
    }
  }

  # HTTP application routing (disabled for security)
  http_application_routing_enabled = false

  # Maintenance window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
      dynamic "not_allowed" {
        for_each = maintenance_window.value.not_allowed
        content {
          end   = not_allowed.value.end
          start = not_allowed.value.start
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Spot instances node pool (when enabled)
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count                 = var.use_spot_instances ? 1 : 0
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = var.vm_size
  
  # Auto-scaling for spot instances
  enable_auto_scaling = true
  min_count          = 0
  max_count          = var.max_count
  
  # Spot instance configuration
  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = var.spot_max_price
  
  # Node configuration
  max_pods        = var.max_pods_per_node
  os_disk_size_gb = var.os_disk_size_gb
  os_type         = "Linux"
  
  # Network
  vnet_subnet_id = var.subnet_id
  
  # Node labels to identify spot instances
  node_labels = merge(var.node_labels, {
    "kubernetes.azure.com/scalesetpriority" = "spot"
    "node-type" = "spot"
  })
  
  # Spot instance taints
  node_taints = concat(var.node_taints, ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"])
  
  tags = var.tags
}

# =============================================================================
# ADDITIONAL NODE POOLS
# =============================================================================
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = each.value.vm_size
  node_count           = each.value.node_count
  
  enable_auto_scaling = each.value.enable_auto_scaling
  min_count          = each.value.min_count
  max_count          = each.value.max_count
  
  priority        = each.value.use_spot_instances ? "Spot" : "Regular"
  eviction_policy = each.value.use_spot_instances ? "Delete" : null
  spot_max_price  = each.value.use_spot_instances ? each.value.spot_max_price : null
  
  max_pods        = each.value.max_pods_per_node
  os_disk_size_gb = each.value.os_disk_size_gb
  os_type         = each.value.os_type
  
  vnet_subnet_id = var.subnet_id
  
  node_labels = each.value.node_labels
  node_taints = each.value.node_taints
  
  tags = var.tags
}
