resource "azurerm_ip_group" "ip_group" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  cidrs               = var.cidrs
  tags                = var.tags
}