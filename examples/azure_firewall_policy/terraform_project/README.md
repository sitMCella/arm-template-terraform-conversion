# Example Terraform Project for Azure Firewall Policy

The following Terraform Project provisions a set of IP Groups, and one Azure Firewall Policy with the rule collections generated from an ARM Template JSON file.

## Setup

Execute the the following commands in order to generate the Terraform modules for the rule collection groups of the Azure Firewall Policy.

```$bash
cd ../../../azure_firewall_policy
chmod +x firewall-policy-conversion.sh
cp ../examples/azure_firewall_policy/ip_groups_mapping.csv .
./firewall-policy-conversion.sh -p ../examples/azure_firewall_policy/firewall_policy_arm_template_example.json
cd ../examples/azure_firewall_policy/terraform_project
```

Copy the generated Terraform modules in the Terraform project.

```$bash
cp -R ../../../azure_firewall_policy/firewall-policy-terraform-module/* networking/westeurope/modules/
```

## Configuration

1. Install Terraform.
2. Create an Azure Service Principal Account in Azure Tenant.
3. Assign the "Contributor" RBAC role on the Azure Tenant to the Azure Service Principal Account.
4. Create the file "secrets/main.json" and insert the Azure Service Principal Account client id and secret.

Use the following template for the file "secrets/main.json".

```
{
  "azure_tenant_id": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "azure_principal_account_client_id": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "azure_principal_account_client_secret": "xxxxxxxxxxxxxxxxx"
}
```

## Development

### Initialize the Terraform Project

```$bash
cd networking/westeurope
terraform init -backend-config="../../secret/main.json" -reconfigure
```

### Verify the Terraform Plan

```$bash
cd networking/westeurope
terraform plan -var-file="../../secret/main.json"
```

### Provision the Terraform Plan

```$bash
cd networking/westeurope
terraform apply -var-file="../../secret/main.json" -auto-approve
```
