provider "azurerm" {
  version = "=2.8.0"
  skip_provider_registration = true

  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.network}-${var.location}"
  location = var.location
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.network}-${var.location}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "harmony_basic_port"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["9000", "6000", "14555"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  /* need add special security group rules */

  security_rule {
    name                       = "otbound-default"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_ddos_protection_plan" "main" {
  name                = "${var.network}-${var.location}-ndpp"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.network}-${var.location}-vn"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/8"]

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.main.id
    enable = true
  }

  subnet {
    name           = "subnet"
    address_prefix = "10.0.0.0/16"
    security_group = azurerm_network_security_group.main.id
  }
}