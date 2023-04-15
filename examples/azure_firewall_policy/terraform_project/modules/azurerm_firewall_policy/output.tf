output "id" {
  value = azurerm_firewall_policy.firewall_policy.id

  description = "The ID of the Firewall Policy."
}

output "name" {
  value = azurerm_firewall_policy.firewall_policy.name

  description = "The name of the Firewall Policy."
}
