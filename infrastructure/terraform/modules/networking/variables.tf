# =============================================================================
# NETWORKING MODULE VARIABLES
# =============================================================================

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_prefix" {
  description = "Prefix for subnet names"
  type        = string
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
