# Azure Firewall Policy ARM Template Terraform Conversion

The following directory contains the Bash script "firewall-policy-conversion.sh" for converting the ARM Template 
JSON file of one Azure Firewall Policy to a set of Terraform modules, one for each rule collection group in the Azure Firewall Policy.

The Bash script "firewall-policy-conversion.sh" requires the file "ip_groups_mapping.csv" located in the same directory.
The file "ip_groups_mapping.csv" defines the mapping between the input variable names in the ARM Template and the Terraform variable 
names for the Azure IP Groups.

## Usage

Generate the file "ip_groups_mapping.csv".

```$bash
az login
chmod +x ip-groups-mapping.sh
./ip-groups-mapping.sh
```

Convert the ARM Template of the Azure Firewall Policy in Terraform modules.

```$bash
chmod +x firewall-policy-conversion.sh
./firewall-policy-conversion.sh -p /path/to/azure_firewall_policy_arm_template.json
```

The directory "firewall-policy-terraform-module" will contain the Terraform modules for the rule collection groups of the Azure Firewall Policy.
