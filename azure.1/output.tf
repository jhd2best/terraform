// output public ip
output "public_ip" {
  value = azurerm_public_ip.mainnet.*.ip_address
}

