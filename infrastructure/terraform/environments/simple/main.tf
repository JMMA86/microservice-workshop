# Simple Terraform environment for microservices

provider "azurerm" {
  features {}
  subscription_id = "f3232678-472a-4a87-b56e-c8cbfa96666e"
}

resource "azurerm_resource_group" "main" {
  name     = "ms-simple-rg"
  location = "East US"
}

variable "microservices" {
  default = [
    "auth-api",
    "frontend",
    "log-message-processor",
    "todos-api",
    "users-api"
  ]
}

resource "azurerm_linux_virtual_machine" "microservice_vm" {
  count               = length(var.microservices)
  name                = "${var.microservices[count.index]}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.microservice_nic[count.index].id]

  admin_password = "P@ssw0rd1234!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk-${var.microservices[count.index]}"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "ms-simple-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "ms-simple-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "microservice_nic" {
  count               = length(var.microservices)
  name                = "${var.microservices[count.index]}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}
