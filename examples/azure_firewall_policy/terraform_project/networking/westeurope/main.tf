module "rg-networking-prod-westeurope" {
  source = "../../modules/azurerm_resource_group"

  location = var.location
  name     = "rg-networking-prod-${var.location}"
}

module "afwp-networking-prod-westeurope" {
  source = "../../modules/azurerm_firewall_policy"

  location            = var.location
  name                = "afwp-networking-prod-${var.location}"
  resource_group_name = module.rg-networking-prod-westeurope.name
  dns = [
    {
      proxy_enabled = true,
      servers       = ["168.63.129.16"]
    }
  ]
}

module "ip-groups" {
  source = "./modules/ip_groups"

  location            = var.location
  resource_group_name = module.rg-networking-prod-westeurope.name
}

module "rcg-azure-prod-westeurope" {
  source = "./modules/rcg_azure_prod_westeurope"

  firewall_policy_id               = module.afwp-networking-prod-westeurope.id
  ipgroup_azure_prod_westeurope_id = module.ip-groups.ipgroup-azure-prod-westeurope_id
}

module "rcg-workload1-dev-westeurope" {
  source = "./modules/rcg_workload1_dev_westeurope"

  firewall_policy_id                  = module.afwp-networking-prod-westeurope.id
  ipgroup_onprem_prod_westeurope_id   = module.ip-groups.ipgroup-onprem-prod-westeurope_id
  ipgroup_azure_prod_westeurope_id    = module.ip-groups.ipgroup-azure-prod-westeurope_id
  ipgroup_workload1_dev_westeurope_id = module.ip-groups.ipgroup-workload1-dev-westeurope_id
}

module "rcg-workload2-prod-westeurope" {
  source = "./modules/rcg_workload2_prod_westeurope"

  firewall_policy_id                   = module.afwp-networking-prod-westeurope.id
  ipgroup_workload3_prod_westeurope_id = module.ip-groups.ipgroup-workload3-prod-westeurope_id
}

module "rcg-workload3-prod-westeurope" {
  source = "./modules/rcg_workload3_prod_westeurope"

  firewall_policy_id                   = module.afwp-networking-prod-westeurope.id
  ipgroup_workload3_prod_westeurope_id = module.ip-groups.ipgroup-workload3-prod-westeurope_id
}

module "rcg-workload4-prod-westeurope" {
  source = "./modules/rcg_workload4_prod_westeurope"

  firewall_policy_id = module.afwp-networking-prod-westeurope.id
}

module "rcg-workload5-prod-westeurope" {
  source = "./modules/rcg_workload4_prod_westeurope"

  firewall_policy_id = module.afwp-networking-prod-westeurope.id
}
