#!/bin/bash

# The following script generates the Terraform modules for an Azure Firewall Policy from 
# the ARM template file exported from the Azure Firewall Policy resource.

# Requirements:
# - Generate the Azure IP Groups mapping file using the Bash script "ip-groups-mapping.sh"
# The IP Groups mapping file requirement can be skipped using the flag "--skip-ip-groups-mapping"

# Inputs:
# - The path of a JSON file with the ARM Template for the Azure Firewall Policy

firewall_policy_arm_template_path=""
skip_ip_groups_mapping=false
firewall_policy_terraform_modules_output_directory="firewall-policy-terraform-module"
ip_groups_mapping_file_name="ip_groups_mapping.csv"
firewall_policy_rule_collection_group=""
replace_file_name="replace.sed"
firewall_policy_rule_collection_group_template_file_path="templates/firewall_policy_rule_collection_group_template.tf"
rule_collection_template_file_path="templates/rule_collection_template.tf"
rule_template_file_path="templates/rule_template.tf"
variables_template_file_path="templates/variables_template.tf"

function display_help() {
    echo "Usage: $0 [Options]"
    echo "   -p, --path                 Path of the ARM Template file for the Azure Firewall Policy resource"
    echo "   --skip-ip-groups-mapping   Skip the IP Groups mapping file"
}

# Parse the Azure Firewall Policy Rule Collection Group name from the ARM Template name parameter
function parse_rule_collection_group_name() {
    rule_collection_group_name=$(echo "$firewall_policy_rule_collection_group" | jq -rc .name)
    rule_collection_group_name=${rule_collection_group_name#*/}
    rule_collection_group_name=${rule_collection_group_name%???}
    echo $rule_collection_group_name
}

function delete_replace_file() {
    if [ -f $replace_file_name ] ; then
        rm $replace_file_name
    fi
}

# Replace the IP Group input parameter with the IP Group variable name
function replaceIpGroup() {
  ip_group_mapping=$1
  local input_ip_groups=$2
  ip_group_parameter=$(echo $ip_group_mapping | sed 's/;.*//')
  ip_group_variable=$(echo $ip_group_mapping | sed 's/.*;//')
  output_ip_groups=${input_ip_groups//"$ip_group_parameter"/"$ip_group_variable"}
  echo $output_ip_groups
}

# Replace the occurrences of the IP Group input parameters from the ARM Template with the IP Group variable name.
function replaceIpGroups() {
  ip_groups="["
  j=0
  input_ip_groups=$1
  while read line; do
    input_ip_groups=$(replaceIpGroup $line $input_ip_groups);
  done < $ip_groups_mapping_file_name
  ip_groups=$input_ip_groups
}

# Check arguments
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
    exit 0
fi
if [ $# -gt 0 ] && ! ([ "$1" == "-p" ] || [ "$1" == "--path" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$3" == "--skip-ip-groups-mapping" ]); then
    display_help
    exit 1
fi
if ! ([ $# -gt 1 ] && [ $# -lt 4 ]) || ! ([ "$1" == "-p" ] || [ "$1" == "--path" ]); then
    display_help
    exit 1
fi
firewall_policy_arm_template_path="$2"
if [ $# -eq 3 ] && [ "$3" == "--skip-ip-groups-mapping" ]; then
    skip_ip_groups_mapping=true
fi

# Check if the ARM Template file of the Azure Firewall Policy exists
if [ ! -f "$firewall_policy_arm_template_path" ]; then
    echo "File \"$firewall_policy_arm_template_path\" not found."
    exit 1
fi

# Check if the IP Groups mapping file exists
if [ $skip_ip_groups_mapping == false ] && [ ! -f "$ip_groups_mapping_file_name" ]; then
    echo "IP Groups mapping file \"$ip_groups_mapping_file_name\" not found."
    exit 1
fi

# Recreate the output directory for the Azure Firewall Policy Terraform modules
if [ -d ${firewall_policy_terraform_modules_output_directory} ]; then
    rm -rf $firewall_policy_terraform_modules_output_directory
fi
mkdir $firewall_policy_terraform_modules_output_directory

echo "Processing..."

# Parse the ARM Template file and generate the Terraform modules for the Azure Firewall Policy rule collection groups.
cat $firewall_policy_arm_template_path | jq -rc .resources[] | while IFS='' read firewall_policy_rule_collection_group; do
    # Filter fhe Network Rule Collection Groups
    rule_collection_group_type=$(echo "$firewall_policy_rule_collection_group" | jq -rc .type)
    if [ $rule_collection_group_type != "Microsoft.Network/firewallPolicies/ruleCollectionGroups" ]; then
        continue
    fi
    # Retrieve the name of the Rule Collection Group
    rule_collection_group_name=$(parse_rule_collection_group_name)
    # Retrieve the priority of the Rule Collection Group
    rule_collection_group_priority=$(echo "$firewall_policy_rule_collection_group" | jq -rc .properties.priority)
    # Create the output directory for the Terraform module of the Rule Collection Group
    output_directory_name=${rule_collection_group_name//[-]/_}
    mkdir -p ${firewall_policy_terraform_modules_output_directory}/${output_directory_name}

    # Create the main.tf file for the Terraform module of the Rule Collection Group
    terraform_module_main_file_path="${firewall_policy_terraform_modules_output_directory}/${output_directory_name}/main.tf"
    touch $terraform_module_main_file_path

    # Create the first section of the Terraform module main.tf of the Rule Collection Group
    echo "s/\${rule_collection_group_terraform_module_name}/${rule_collection_group_name}/" > $replace_file_name
    echo "s/\${rule_collection_group_name}/${rule_collection_group_name}/" >> $replace_file_name
    echo "s/\${rule_collection_group_priority}/${rule_collection_group_priority}/" >> $replace_file_name

    sed -f $replace_file_name $firewall_policy_rule_collection_group_template_file_path >> $terraform_module_main_file_path
    $(delete_replace_file)
   
    # Loop through the rule collections inside each Azure Firewall Policy rule collection group.
    rule_collections_count=$(echo "$firewall_policy_rule_collection_group" | jq '.properties.ruleCollections | length')
    rule_collections_index=0
    echo "$firewall_policy_rule_collection_group" | jq -rc .properties.ruleCollections[] | while IFS='' read rule_collection; do
        # Filter the Firewall Policy rule collections
        rule_collection_type=$(echo "$rule_collection" | jq -rc .ruleCollectionType)
        if [[ $rule_collection_type != "FirewallPolicyFilterRuleCollection" ]]; then
            continue
        fi
        
        ((rule_collections_index++))
        if [ $rule_collections_index -gt 1 ]; then
            echo "    }," >> $terraform_module_main_file_path
        fi
        
        # Create an item in the "network_rule_collection" array in the Terraform module main.tf of the Rule Collection Group
        rule_collection_name=$(echo "$rule_collection" | jq -rc .name)
        rule_collection_priority=$(echo "$rule_collection" | jq -rc .priority)
        rule_collection_action=$(echo "$rule_collection" | jq -rc .action.type)
        $(delete_replace_file)
        echo "s/\${rule_collection_name}/${rule_collection_name}/" >> $replace_file_name
        echo "s/\${rule_collection_priority}/${rule_collection_priority}/" >> $replace_file_name
        echo "s/\${rule_collection_action}/${rule_collection_action}/" >> $replace_file_name

        sed -f $replace_file_name $rule_collection_template_file_path >> $terraform_module_main_file_path
        $(delete_replace_file)

        # Loop through the rules inside the rule collection
        rules_count=$(echo "$rule_collection" | jq '.rules | length')
        rules_index=0
        echo "$rule_collection" | jq -rc .rules[] | while IFS='' read rule; do
            # Filter the Network rules
            rule_type=$(echo "$rule" | jq -rc .ruleType)
            if [[ $rule_type != "NetworkRule" ]]; then
                continue
            fi
            # Create an item in the "rule" array inside the rule collection in the Terraform module main.tf of the Rule Collection Group
            $(delete_replace_file)
            rule_name=$(echo "$rule" | jq -rc .name)
            echo "s/\${rule_name}/${rule_name}/" > $replace_file_name
            source_addresses=$(echo "$rule" | jq -rc .sourceAddresses)
            source_addresses=${source_addresses//\//\\/}
            echo "s/\${source_addresses}/${source_addresses}/" >> $replace_file_name
            destination_addresses=$(echo "$rule" | jq -rc .destinationAddresses)
            destination_addresses=${destination_addresses//\//\\/}
            echo "s/\${destination_addresses}/${destination_addresses}/" >> $replace_file_name
            protocols=$(echo "$rule" | jq -rc .ipProtocols)
            echo "s/\${protocols}/${protocols}/" >> $replace_file_name
            source_ip_groups=$(echo "$rule" | jq -rc .sourceIpGroups)
            if [ $skip_ip_groups_mapping == false ]; then
                replaceIpGroups $source_ip_groups
            else
                ip_groups=$source_ip_groups
            fi
            echo "s/\${source_ip_groups}/${ip_groups}/" >> $replace_file_name
            destination_ip_groups=$(echo "$rule" | jq -rc .destinationIpGroups)
            if [ $skip_ip_groups_mapping == false ]; then
                replaceIpGroups $destination_ip_groups
            else
                ip_groups=$destination_ip_groups
            fi
            echo "s/\${destination_ip_groups}/${ip_groups}/" >> $replace_file_name
            destination_ports=$(echo "$rule" | jq -rc .destinationPorts)
            echo "s/\${destination_ports}/${destination_ports}/" >> $replace_file_name
            
            ((rules_index++))
            if [ $rules_index -gt 1 ]; then
                echo "        }," >> $terraform_module_main_file_path
            fi
            
            sed -f $replace_file_name $rule_template_file_path >> $terraform_module_main_file_path
            $(delete_replace_file)
        done
        if [ ! $rules_count == "0" ]; then
            echo "        }" >> $terraform_module_main_file_path
        fi
        echo "      ]" >> $terraform_module_main_file_path
    done

    # Create the output.tf file for the Terraform module of the Rule Collection Group
    terraform_module_output_file_path="${firewall_policy_terraform_modules_output_directory}/${output_directory_name}/output.tf"
    touch $terraform_module_output_file_path

    # Create the variables.tf file for the Terraform module of the Rule Collection Group
    terraform_module_variables_file_path="${firewall_policy_terraform_modules_output_directory}/${output_directory_name}/variables.tf"
    cp $variables_template_file_path $terraform_module_variables_file_path

    if [ ! $rule_collections_count == "0" ]; then
        echo "    }" >> $terraform_module_main_file_path
    fi
    echo "  ]" >> $terraform_module_main_file_path
    echo "}" >> $terraform_module_main_file_path
done

cd ${firewall_policy_terraform_modules_output_directory}
find . -type f -name '*.tf' -print | uniq | xargs -n1 terraform fmt
cd ..

echo "Process completed. The generated Terraform modules are located in the directory \"$firewall_policy_terraform_modules_output_directory\""