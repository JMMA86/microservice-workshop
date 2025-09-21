# =============================================================================
# NETWORKING MODULE - VIRTUAL NETWORK AND SUBNETS
# Provides isolated networking for AKS and Application Gateway
# =============================================================================

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# AKS Subnet
resource "azurerm_subnet" "aks" {
  name                 = "${var.subnet_prefix}-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_cidr]
}

# Application Gateway Subnet
resource "azurerm_subnet" "app_gateway" {
  name                 = "${var.subnet_prefix}-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.app_gateway_subnet_cidr]
}

# Private Endpoints Subnet (for Key Vault, ACR, etc.)
resource "azurerm_subnet" "private_endpoints" {
  name                 = "${var.subnet_prefix}-private"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_endpoints_subnet_cidr]
  
  private_endpoint_network_policies = "Disabled"
}

# Network Security Group for AKS
resource "azurerm_network_security_group" "aks" {
  name                = "${var.subnet_prefix}-aks-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow internal AKS communication
  security_rule {
    name                       = "AllowAKSInternal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.aks_subnet_cidr
    destination_address_prefix = var.aks_subnet_cidr
  }

  # Allow Application Gateway to AKS
  security_rule {
    name                       = "AllowAppGatewayToAKS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "8080"]
    source_address_prefix      = var.app_gateway_subnet_cidr
    destination_address_prefix = var.aks_subnet_cidr
  }
}

# Network Security Group for Application Gateway
resource "azurerm_network_security_group" "app_gateway" {
  name                = "${var.subnet_prefix}-appgw-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow Internet to Application Gateway
  security_rule {
    name                       = "AllowInternetToAppGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = var.app_gateway_subnet_cidr
  }

  # Allow Azure Load Balancer
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Required for Application Gateway management
  security_rule {
    name                       = "AllowGatewayManager"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
}

# Associate NSG with AKS subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Associate NSG with Application Gateway subnet
resource "azurerm_subnet_network_security_group_association" "app_gateway" {
  subnet_id                 = azurerm_subnet.app_gateway.id
  network_security_group_id = azurerm_network_security_group.app_gateway.id
}

# Route Table for better control
resource "azurerm_route_table" "main" {
  name                = "${var.subnet_prefix}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  route {
    name           = "DefaultRoute"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

# Associate Route Table with AKS subnet
resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.main.id
}
