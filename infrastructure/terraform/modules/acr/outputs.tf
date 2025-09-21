# =============================================================================
# ACR MODULE OUTPUTS
# =============================================================================

output "registry_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "Admin username for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "Admin password for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "identity" {
  description = "Managed identity information"
  value = azurerm_container_registry.main.identity
}

output "private_endpoint_id" {
  description = "ID of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.acr[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.acr[0].private_service_connection[0].private_ip_address : null
}

output "webhooks" {
  description = "Information about created webhooks"
  value = {
    for name, webhook in azurerm_container_registry_webhook.webhook : name => {
      id         = webhook.id
      service_uri = webhook.service_uri
    }
  }
}

output "build_tasks" {
  description = "Information about created build tasks"
  value = {
    for name, task in azurerm_container_registry_task.build_task : name => {
      id   = task.id
      name = task.name
    }
  }
}

# Connection commands
output "docker_login_command" {
  description = "Command to login to ACR with Docker"
  value       = "az acr login --name ${azurerm_container_registry.main.name}"
}

output "docker_login_server" {
  description = "Docker login server for use in CI/CD"
  value       = azurerm_container_registry.main.login_server
}

# Image management
output "image_push_example" {
  description = "Example command to push an image"
  value       = "docker tag myapp:latest ${azurerm_container_registry.main.login_server}/myapp:latest && docker push ${azurerm_container_registry.main.login_server}/myapp:latest"
}

output "helm_registry_login" {
  description = "Command to login to ACR with Helm"
  value       = "helm registry login ${azurerm_container_registry.main.login_server}"
}
