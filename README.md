# ARM Template Terraform Conversion

The following project contains a set of scripts for converting Azure ARM Templates in Terraform modules.

The automation scripts can be used in order to keep the Terraform projects aligned with manual changes in the Azure environment.

## Azure Firewall Policy

The directory "azure_firewall_policy" contains the Bash script "firewall-policy-conversion.sh" for converting the ARM Template file of one Azure Firewall Policy to a set of Terraform modules, one for each rule collection group defined in the Azure Firewall Policy.

Read the [README.md](https://github.com/sitMCella/arm-template-terraform-conversion/blob/main/azure_firewall_policy/README.md) for more details.

The directory "examples/azure_firewall_policy" contains an example Terraform Project.

Read the [README.md](https://github.com/sitMCella/arm-template-terraform-conversion/tree/main/examples/azure_firewall_policy/README.md) for more details.
