variable "location" {
  description = "(Required) The location of the Azure resources."
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group in which to create the IP groups."
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the IP groups."

  default = {}
}
