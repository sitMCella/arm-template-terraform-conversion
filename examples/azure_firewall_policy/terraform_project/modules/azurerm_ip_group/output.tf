output "id" {
  value = azurerm_ip_group.ip_group.id

  description = "The ID of the IP group."
}

output "cidrs" {
  value = azurerm_ip_group.ip_group.cidrs

  description = "The list of CIDRs or IP addresses of the IP group."
}
