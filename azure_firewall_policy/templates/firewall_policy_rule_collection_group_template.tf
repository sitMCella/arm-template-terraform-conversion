module "${rule_collection_group_terraform_module_name}" {
  source = "../../../../modules/azurerm_firewall_policy_rule_collection_group"

  name               = "${rule_collection_group_name}"
  firewall_policy_id = var.firewall_policy_id
  priority           = ${rule_collection_group_priority}

  application_rule_collection = []
  network_rule_collection = [
