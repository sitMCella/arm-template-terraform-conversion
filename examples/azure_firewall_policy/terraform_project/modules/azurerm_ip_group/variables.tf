variable "name" {
  description = "(Required) Specifies the name of the IP group."
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group in which to create the IP group."
}

variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource exists."
}

variable "cidrs" {
  description = "(Optional) A list of CIDRs or IP addresses."

  default = []
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."

  default = {}
}
