output "id" {
  value = azurerm_resource_group.resource_group.id

  description = "The ID of the Resource Group."
}

output "name" {
  value = azurerm_resource_group.resource_group.name

  description = "The name of the Resource Group."
}
