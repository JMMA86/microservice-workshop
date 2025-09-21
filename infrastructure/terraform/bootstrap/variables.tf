# =============================================================================
# BOOTSTRAP VARIABLES
# Configuration for Terraform state backend infrastructure
# =============================================================================

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
