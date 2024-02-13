variable "name" {
  description = "(Required) The name which should be used for this Firewall Policy Rule Collection Group."
}

variable "firewall_policy_id" {
  description = "(Required) The ID of the Firewall Policy where the Firewall Policy Rule Collection Group should exist."
}

variable "priority" {
  description = "(Required) The priority of the Firewall Policy Rule Collection Group. The range is 100-65000."
}

variable "application_rule_collection" {
  description = "(Optional) One or more application_rule_collection blocks as defined below."

  type = list(object({
    name     = string
    action   = string
    priority = number
    rule = list(object({
      name             = string
      source_addresses = list(string)
      source_ip_groups = list(string)
      protocols = list(object({
        type = string
        port = string
      }))
      destination_fqdns     = list(string)
      destination_fqdn_tags = list(string)
    }))
  }))

  default = []
}

variable "nat_rule_collection" {
  description = "(Optional) One or more nat_rule_collection blocks as defined below."

  type = list(object({
    name     = string
    action   = string
    priority = number
    rule = list(object({
      name                = string
      protocols           = list(string)
      source_addresses    = list(string)
      source_ip_groups    = list(string)
      destination_address = string
      destination_ports   = list(string)
      translated_address  = string
      translated_port     = string
    }))
  }))

  default = []
}

variable "network_rule_collection" {
  description = "(Optional) One or more network_rule_collection blocks as defined below."

  type = list(object({
    name     = string
    action   = string
    priority = number
    rule = list(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = list(string)
      source_ip_groups      = list(string)
      destination_ports     = list(string)
      destination_addresses = list(string)
      destination_ip_groups = list(string)
      destination_fqdns     = list(string)
    }))
  }))

  default = []
}
