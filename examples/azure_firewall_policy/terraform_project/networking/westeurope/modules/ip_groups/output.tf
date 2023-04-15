output "ipgroup-onprem-prod-westeurope_id" {
  value = module.ipgroup-onprem-prod-westeurope.id

  description = "The ID of the IP group ipgroup-onprem-prod-westeurope."
}

output "ipgroup-azure-prod-westeurope_id" {
  value = module.ipgroup-azure-prod-westeurope.id

  description = "The ID of the IP group ipgroup-azure-prod-westeurope."
}

output "ipgroup-workload1-dev-westeurope_id" {
  value = module.ipgroup-workload1-dev-westeurope.id

  description = "The ID of the IP group ipgroup-workload1-dev-westeurope."
}

output "ipgroup-workload3-prod-westeurope_id" {
  value = module.ipgroup-workload3-prod-westeurope.id

  description = "The ID of the IP group ipgroup-workload3-prod-westeurope."
}
