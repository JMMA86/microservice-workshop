# =============================================================================
# BOOTSTRAP VARIABLES
# Configuration for Terraform state backend infrastructure
# =============================================================================

variable "subscription_id" {
  description = "Azure Subscription ID where the Terraform state resources will be created"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for the Terraform state infrastructure"
  type        = string
  default     = "East US"
}

variable "environment_prefix" {
  description = "Prefix for environment-specific resources"
  type        = string
  default     = "msworkshop"
}
