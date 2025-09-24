# =============================================================================
# NETWORKING MODULE OUTPUTS
# =============================================================================

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "Name of the AKS subnet"
  value       = azurerm_subnet.aks.name
}

output "aks_nsg_id" {
  description = "ID of the AKS Network Security Group"
  value       = azurerm_network_security_group.aks.id
}
