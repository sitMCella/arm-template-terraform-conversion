output "id" {
  value = azurerm_firewall_policy_rule_collection_group.firewall_policy_rule_collection_group.id

  description = "The ID of the Firewall Policy Rule Collection Group."
}

output "name" {
  value = azurerm_firewall_policy_rule_collection_group.firewall_policy_rule_collection_group.name

  description = "The name of the Firewall Policy Rule Collection Group."
}
