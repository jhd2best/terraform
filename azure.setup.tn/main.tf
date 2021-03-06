provider "azurerm" {
  version                    = "=2.8.0"
  skip_provider_registration = true

  features {}
}

resource "azurerm_resource_group" "testnet" {
  name     = "${var.network}-${var.location}"
  location = var.location
}

resource "azurerm_network_security_group" "testnet" {
  name                = "${var.network}-${var.location}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.testnet.name

  security_rule {
    name                       = "harmony"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["9000", "9100", "6000", "9500", "6060"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "manage"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

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

resource "azurerm_network_ddos_protection_plan" "testnet" {
  name                = "${var.network}-${var.location}-ndpp"
  location            = var.location
  resource_group_name = azurerm_resource_group.testnet.name
}

resource "azurerm_virtual_network" "testnet" {
  name                = "${var.network}-${var.location}-vn"
  location            = var.location
  resource_group_name = azurerm_resource_group.testnet.name
  address_space       = ["10.0.0.0/8"]

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.testnet.id
    enable = true
  }

  subnet {
    name           = "subnet"
    address_prefix = "10.10.0.0/16"
    security_group = azurerm_network_security_group.testnet.id
  }
}
