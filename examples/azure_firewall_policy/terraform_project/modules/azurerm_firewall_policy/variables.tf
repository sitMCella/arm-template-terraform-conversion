variable "location" {
  description = "(Required) The Azure Region where the Firewall Policy should exist."
}

variable "name" {
  description = "(Required) The name which should be used for this Firewall Policy."
}

variable "resource_group_name" {
  description = "(Required) The name of the Resource Group where the Firewall Policy should exist."
}

variable "sku" {
  description = "(Optional) The SKU Tier of the Firewall Policy. Possible values are Standard, Premium and Basic."

  default = "Standard"
}

variable "dns" {
  description = "(Optional) A dns block as defined below."

  type = object({
    proxy_enabled = bool
    servers       = list(string)
  })
  default = null
}

variable "threat_intelligence_allowlist" {
  description = "(Optional) A threat_intelligence_allowlist block as defined below."

  type = object({
    fqdns        = list(string)
    ip_addresses = list(string)
  })
}

variable "tags" {
  description = "(Optional) A mapping of tags which should be assigned to the Firewall Policy."

  default = {}
}
