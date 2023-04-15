variable "location" {
  description = "(Required) The Azure Region where the Resource Group should exist."
}

variable "name" {
  description = "(Required) The Name which should be used for this Resource Group."
}

variable "tags" {
  description = "(Optional) A mapping of tags which should be assigned to the Resource Group."

  default = {}
}
