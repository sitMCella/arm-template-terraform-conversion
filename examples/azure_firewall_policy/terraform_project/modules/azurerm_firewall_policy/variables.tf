variable "location" {
  description = "(Required) The Azure Region where the Firewall Policy should exist."
}

variable "name" {
  description = "(Required) The name which should be used for this Firewall Policy."
}

variable "resource_group_name" {
  description = "(Required) The name of the Resource Group where the Firewall Policy should exist."
}

variable "dns" {
  description = "(Required) A dns block as defined below."

  type = list(object({
    proxy_enabled = bool
    servers       = list(string)
  }))
}

variable "sku" {
  description = "(Optional) The SKU Tier of the Firewall Policy. Possible values are Standard, Premium and Basic."

  default = "Standard"
}

variable "tags" {
  description = "(Optional) A mapping of tags which should be assigned to the Firewall Policy."

  default = {}
}
