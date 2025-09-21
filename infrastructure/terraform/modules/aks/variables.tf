# =============================================================================
# AKS MODULE VARIABLES
# =============================================================================

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes"
  type        = string
  default     = "1.27"
}

variable "sku_tier" {
  description = "SKU tier for the AKS cluster"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Paid"], var.sku_tier)
    error_message = "SKU tier must be either 'Free' or 'Paid'."
  }
}

# Default node pool configuration
variable "node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B2s"
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the node pool"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "use_spot_instances" {
  description = "Use spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (USD per hour)"
  type        = number
  default     = 0.01
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 110
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "max_surge" {
  description = "Maximum surge for node pool upgrades"
  type        = string
  default     = "10%"
}

variable "subnet_id" {
  description = "ID of the subnet for AKS nodes"
  type        = string
}

# Network configuration
variable "network_plugin" {
  description = "Network plugin for AKS"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be either 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "Network policy for AKS"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "calico"], var.network_policy)
    error_message = "Network policy must be either 'azure' or 'calico'."
  }
}

variable "dns_service_ip" {
  description = "DNS service IP for AKS"
  type        = string
  default     = "10.254.0.10"
}

variable "service_cidr" {
  description = "Service CIDR for AKS"
  type        = string
  default     = "10.254.0.0/16"
}

# Monitoring
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = null
}

# Auto-scaler profile
variable "auto_scaler_profile" {
  description = "Auto-scaler profile configuration"
  type = object({
    balance_similar_node_groups      = bool
    expander                        = string
    max_graceful_termination_sec    = string
    max_node_provisioning_time      = string
    max_unready_nodes              = number
    max_unready_percentage         = number
    new_pod_scale_up_delay         = string
    scale_down_delay_after_add     = string
    scale_down_delay_after_delete  = string
    scale_down_delay_after_failure = string
    scan_interval                  = string
    scale_down_unneeded           = string
    scale_down_unready            = string
    scale_down_utilization_threshold = number
  })
  default = {
    balance_similar_node_groups      = false
    expander                        = "random"
    max_graceful_termination_sec    = "600"
    max_node_provisioning_time      = "15m"
    max_unready_nodes              = 3
    max_unready_percentage         = 45
    new_pod_scale_up_delay         = "10s"
    scale_down_delay_after_add     = "10m"
    scale_down_delay_after_delete  = "10s"
    scale_down_delay_after_failure = "3m"
    scan_interval                  = "10s"
    scale_down_unneeded           = "10m"
    scale_down_unready            = "20m"
    scale_down_utilization_threshold = 0.5
  }
}

# Azure AD integration
variable "enable_azure_ad_integration" {
  description = "Enable Azure AD integration"
  type        = bool
  default     = false
}

variable "azure_ad_admin_group_object_ids" {
  description = "Object IDs of Azure AD groups that should have admin access"
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC"
  type        = bool
  default     = false
}

# Node configuration
variable "node_labels" {
  description = "Labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Taints to apply to nodes in key=value:effect format"
  type        = list(string)
  default     = []
}

# Additional node pools
variable "additional_node_pools" {
  description = "Additional node pools configuration"
  type = map(object({
    vm_size              = string
    node_count           = number
    enable_auto_scaling  = bool
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
variable "maintenance_window" {
  description = "Maintenance window configuration"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
