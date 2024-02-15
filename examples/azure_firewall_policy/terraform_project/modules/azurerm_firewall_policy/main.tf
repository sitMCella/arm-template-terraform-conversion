resource "azurerm_firewall_policy" "firewall_policy" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  dynamic "dns" {
    for_each = var.dns != null ? [1] : []
    content {
      servers       = var.dns.servers
      proxy_enabled = var.dns.proxy_enabled
    }
  }
  dynamic "threat_intelligence_allowlist" {
    for_each = var.threat_intelligence_allowlist != null ? [1] : []
    content {
      fqdns        = var.threat_intelligence_allowlist.fqdns
      ip_addresses = var.threat_intelligence_allowlist.ip_addresses
    }
  }
  tags = var.tags
}
