module "ipgroup-onprem-prod-westeurope" {
  source = "../../../../modules/azurerm_ip_group"

  name                = "ipgroup-onprem-prod-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  cidrs               = ["10.128.0.0/15"]
  tags                = var.tags
}

module "ipgroup-azure-prod-westeurope" {
  source = "../../../../modules/azurerm_ip_group"

  name                = "ipgroup-azure-prod-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  cidrs               = ["10.0.0.0/15"]
  tags                = var.tags
}

module "ipgroup-workload1-dev-westeurope" {
  source = "../../../../modules/azurerm_ip_group"

  name                = "ipgroup-workload1-dev-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  cidrs               = ["10.0.0.0/21"]
  tags                = var.tags
}

module "ipgroup-workload3-prod-westeurope" {
  source = "../../../../modules/azurerm_ip_group"

  name                = "ipgroup-workload3-prod-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  cidrs               = ["10.0.8.0/21"]
  tags                = var.tags
}
