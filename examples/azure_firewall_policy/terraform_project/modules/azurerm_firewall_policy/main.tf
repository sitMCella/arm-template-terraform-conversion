resource "azurerm_firewall_policy" "firewall_policy" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  dynamic "dns" {
    for_each = var.dns
    content {
      servers       = dns.value["servers"]
      proxy_enabled = dns.value["proxy_enabled"]
    }
  }
  sku  = var.sku
  tags = var.tags
}
