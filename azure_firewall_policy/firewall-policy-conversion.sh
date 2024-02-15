#!/bin/bash

# The following script generates the Terraform modules of the rule collection groups 
# for an Azure Firewall Policy from the ARM template file exported from the Azure Firewall
# Policy resource.

# Requirements:
# - Export the ARM Template for the Azure Firewall Policy resource.
# - Generate the Azure IP Groups mapping file using the Bash script "ip-groups-mapping.sh".
# The IP Groups mapping file requirement can be skipped using the flag "--skip-ip-groups-mapping".

# Inputs:
# - The path of a JSON file with the ARM Template for the Azure Firewall Policy.
# - (Optional) The name of the rule collection group.

firewall_policy_arm_template_path=""
skip_ip_groups_mapping=false
firewall_policy_terraform_modules_output_directory="firewall-policy-terraform-module"
ip_groups_mapping_file_name="ip_groups_mapping.csv"
firewall_policy_rule_collection_group=""
replace_file_name="replace.sed"
network_rule_collections_file_name="network_rule_collections.txt"
application_rule_collections_file_name="application_rule_collections.txt"
rule_collection_file_name="rule_collection.txt"
rules_file_name="rules.txt"
ip_groups_rule_collection_group_file_name="ip_groups_rule_collection_group.txt"
firewall_rule_type_file_name="firewall_rule_type.txt"
firewall_policy_rule_collection_group_template_file_path="templates/firewall_policy_rule_collection_group_template.tf"
rule_collection_template_file_path="templates/rule_collection_template.tf"
network_rule_template_file_path="templates/network_rule_template.tf"
application_rule_template_file_path="templates/application_rule_template.tf"
variables_template_file_path="templates/variables_template.tf"

function display_help() {
    echo "Usage: -p <file_path> [-g <group_name>] --skip-ip-groups"
    echo "  -p, --path                   Path of the ARM Template file for the Azure Firewall Policy"
    echo "  (Optional) -g, --group       Name of the rule collection group"
    echo "  (Optional) --skip-ip-groups  Skip the IP Groups mapping file"
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
if [ $# -eq 0 ]; then
    display_help
    exit 0
fi
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
    exit 0
fi
if [ $# -eq 1 ] || ! ([ "$1" == "-p" ] || [ "$1" == "--path" ]); then
    display_help
    exit 1
fi
if [ $# -gt 2 ] && ! ([ "$3" == "-g" ] || [ "$3" == "--group" ] || [ "$3" == "--skip-ip-groups" ]); then
    display_help
    exit 1
fi
if [ $# -gt 2 ] && ([ "$3" == "-g" ] || [ "$3" == "--group" ]) && [ $# -lt 4 ]; then
    display_help
    exit 1
fi
if [ $# -gt 3 ] && [ "$4" == "--skip-ip-groups" ] && ! ([ "$5" == "--skip-ip-groups" ]); then
    display_help
    exit 1
fi
firewall_policy_arm_template_path="$2"
rule_collection_group_name_filter="null"
if [ $# -gt 2 ] && ([ "$3" == "-g" ] || [ "$3" == "--group" ]); then
    rule_collection_group_name_filter="$4"
fi
if [ $# -eq 3 ] && [ "$3" == "--skip-ip-groups" ]; then
    skip_ip_groups_mapping=true
fi
if [ $# -eq 5 ] && [ "$5" == "--skip-ip-groups" ]; then
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
    # Skip the evaluation of the Rule Collection Group if the name does not correspond to the filter
    if [ $rule_collection_group_name_filter != "null" ] && [ $rule_collection_group_name_filter != $rule_collection_group_name ]; then
        continue
    fi

    echo "Rule Collection Group name: " $rule_collection_group_name

    # Initialize the temporary files for the Rule Collections
    if [ -f $network_rule_collections_file_name ] ; then
        rm $network_rule_collections_file_name
    fi
    touch $network_rule_collections_file_name
    echo "  network_rule_collection = [" >> $network_rule_collections_file_name
    if [ -f $application_rule_collections_file_name ] ; then
        rm $application_rule_collections_file_name
    fi
    touch $application_rule_collections_file_name
    echo "  application_rule_collection = [" >> $application_rule_collections_file_name
    if [ -f $ip_groups_rule_collection_group_file_name ] ; then
        rm $ip_groups_rule_collection_group_file_name
    fi
    touch $ip_groups_rule_collection_group_file_name

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
        # Initialize the temporary file for the firewall rule collection
        if [ -f $rule_collection_file_name ] ; then
            rm $rule_collection_file_name
        fi
        touch $rule_collection_file_name
        
        # Create an item in the Rule Collection
        rule_collection_name=$(echo "$rule_collection" | jq -rc .name)
        rule_collection_priority=$(echo "$rule_collection" | jq -rc .priority)
        rule_collection_action=$(echo "$rule_collection" | jq -rc .action.type)
        $(delete_replace_file)
        echo "s/\${rule_collection_name}/${rule_collection_name}/" >> $replace_file_name
        echo "s/\${rule_collection_priority}/${rule_collection_priority}/" >> $replace_file_name
        echo "s/\${rule_collection_action}/${rule_collection_action}/" >> $replace_file_name

        echo "Rule Collection name: " $rule_collection_name

        sed -f $replace_file_name $rule_collection_template_file_path >> $rule_collection_file_name
        $(delete_replace_file)

        if [ -f $rules_file_name ] ; then
            rm $rules_file_name
        fi
        touch $rules_file_name

        # Loop through the rules in the rule collection
        rules_count=$(echo "$rule_collection" | jq '.rules | length')
        rules_index=0
        echo "$rule_collection" | jq -rc .rules[] | while IFS='' read rule; do
            # Retrieve the rule type
            rule_type=$(echo "$rule" | jq -rc .ruleType)
            echo $rule_type > $firewall_rule_type_file_name
            # Filter the Network rules
            if [[ $rule_type == "NetworkRule" ]]; then
                # Create one item in the "rule" array inside the network rule collection
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
                    ip_groups_list=$(echo $ip_groups | cut -c 2- | rev | cut -c 2- | rev)
                    ip_groups_list=(${ip_groups_list//,/ })
                    for i in "${ip_groups_list[@]}"; do
                        ip_group_variable_name=$(echo $i | cut -c 5-)
                        isInFile=$(cat $ip_groups_rule_collection_group_file_name | grep -c $ip_group_variable_name)
                        if [[ isInFile -eq 0 ]]; then
                            echo $ip_group_variable_name >> $ip_groups_rule_collection_group_file_name
                        fi
                    done
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
                destination_fqdns=$(echo "$rule" | jq -rc .destinationFqdns)
                destination_fqdns=${destination_fqdns//\//\\/}
                echo "s/\${destination_fqdns}/${destination_fqdns}/" >> $replace_file_name
                destination_ports=$(echo "$rule" | jq -rc .destinationPorts)
                echo "s/\${destination_ports}/${destination_ports}/" >> $replace_file_name
                
                ((rules_index++))
                if [ $rules_index -gt 1 ]; then
                    echo "        }," >> $rules_file_name
                fi
                
                sed -f $replace_file_name $network_rule_template_file_path >> $rules_file_name
                $(delete_replace_file)
            fi
            # Filter the Application rules
            if [[ $rule_type == "ApplicationRule" ]]; then
                # Create one item in the "rule" array inside the application rule collection
                $(delete_replace_file)
                rule_name=$(echo "$rule" | jq -rc .name)
                echo "s/\${rule_name}/${rule_name}/" > $replace_file_name
                source_addresses=$(echo "$rule" | jq -rc .sourceAddresses)
                source_addresses=${source_addresses//\//\\/}
                echo "s/\${source_addresses}/${source_addresses}/" >> $replace_file_name
                source_ip_groups=$(echo "$rule" | jq -rc .sourceIpGroups)
                if [ $skip_ip_groups_mapping == false ]; then
                    replaceIpGroups $source_ip_groups
                else
                    ip_groups=$source_ip_groups
                fi
                echo "s/\${source_ip_groups}/${ip_groups}/" >> $replace_file_name
                target_fqdns=$(echo "$rule" | jq -rc .targetFqdns)
                target_fqdns=${target_fqdns//\//\\/}
                echo "s/\${target_fqdns}/${target_fqdns}/" >> $replace_file_name
                fqdn_tags=$(echo "$rule" | jq -rc .fqdnTags)
                echo "s/\${fqdn_tags}/${fqdn_tags}/" >> $replace_file_name
                destination_ports=$(echo "$rule" | jq -rc .destinationPorts)
                echo "s/\${destination_ports}/${destination_ports}/" >> $replace_file_name
                protocol_type=$(echo "$rule" | jq -rc .protocols[0].protocolType)
                echo "s/\${protocol_type}/${protocol_type}/" >> replace.sed
                protocol_port=$(echo "$rule" | jq -rc .protocols[0].port)
                echo "s/\${protocol_port}/${protocol_port}/" >> replace.sed

                ((rules_index++))
                if [ $rules_index -gt 1 ]; then
                    echo "        }," >> $rules_file_name
                fi
                
                sed -f $replace_file_name $application_rule_template_file_path >> $rules_file_name
                $(delete_replace_file)
            fi
        done
        if [ ! $rules_count == "0" ]; then
            echo "        }" >> $rules_file_name
        fi
        firewall_rule_collection_type="null"
        # Retrieve the rule collection type
        if [ -f $firewall_rule_type_file_name ]; then
           firewall_rule_collection_type=$(cat $firewall_rule_type_file_name)
        fi
        # Configure the array with the network rule collections
        if [[ $firewall_rule_collection_type == "NetworkRule" ]]; then
            cat $rule_collection_file_name >> $network_rule_collections_file_name
            cat $rules_file_name >> $network_rule_collections_file_name
            echo "      ]" >> $network_rule_collections_file_name
            if [[ $rule_collections_index -lt $rule_collections_count ]]; then
                echo "    }," >> $network_rule_collections_file_name
            else
                echo "    }" >> $network_rule_collections_file_name
            fi
        fi
        # Configure the array with the application rule collections
        if [[ $firewall_rule_collection_type == "ApplicationRule" ]]; then
            cat $rule_collection_file_name >> $application_rule_collections_file_name
            cat $rules_file_name >> $application_rule_collections_file_name
            echo "      ]" >> $application_rule_collections_file_name
            if [[ $rule_collections_index -lt $rule_collections_count ]]; then
                echo "    }," >> $application_rule_collections_file_name
            else
                echo "    }" >> $application_rule_collections_file_name
            fi
        fi
        if [ -f $rule_collection_file_name ]; then
            rm $rule_collection_file_name
        fi
        if [ -f $rules_file_name ]; then
            rm $rules_file_name
        fi
        if [ -f $firewall_rule_type_file_name ]; then
            rm $firewall_rule_type_file_name
        fi
    done

    # Add the network rule collections to the main.tf file
    echo "  ]" >> $network_rule_collections_file_name
    cat $network_rule_collections_file_name >> $terraform_module_main_file_path
    if [ -f $network_rule_collections_file_name ] ; then
        rm $network_rule_collections_file_name
    fi

    # Add the application rule collections to the main.tf file
    echo "  ]" >> $application_rule_collections_file_name
    cat $application_rule_collections_file_name >> $terraform_module_main_file_path
    if [ -f $application_rule_collections_file_name ] ; then
        rm $application_rule_collections_file_name
    fi

    # Create the output.tf file for the Terraform module of the Rule Collection Group
    terraform_module_output_file_path="${firewall_policy_terraform_modules_output_directory}/${output_directory_name}/output.tf"
    touch $terraform_module_output_file_path

    # Create the variables.tf file for the Terraform module of the Rule Collection Group
    terraform_module_variables_file_path="${firewall_policy_terraform_modules_output_directory}/${output_directory_name}/variables.tf"
    echo "s/\${variable_name}/firewall_policy_id/" > $replace_file_name
    echo "s/\${description}/(Required) The ID of the Azure Firewall Policy./" >> $replace_file_name
    sed -f $replace_file_name $variables_template_file_path >> $terraform_module_variables_file_path
    $(delete_replace_file)

    while IFS= read -r ip_group_variable_name; do
        echo "s/\${variable_name}/${ip_group_variable_name}/" > $replace_file_name
        ip_group_name=$(echo $ip_group_variable_name | rev | cut -c 4- | rev)
        ip_group_name=${ip_group_name//_/-}
        echo "s/\${description}/(Required) The ID of the IP Group ${ip_group_name}./" >> $replace_file_name
        sed -f $replace_file_name $variables_template_file_path >> $terraform_module_variables_file_path
        $(delete_replace_file)
    done < $ip_groups_rule_collection_group_file_name

    if [ -f $ip_groups_rule_collection_group_file_name ] ; then
        rm $ip_groups_rule_collection_group_file_name
    fi

    echo "}" >> $terraform_module_main_file_path
done

cd ${firewall_policy_terraform_modules_output_directory}
echo "Format Terraform code..."
find . -type f -name '*.tf' -print | uniq | xargs -n1 terraform fmt
cd ..

echo "Process completed. The generated Terraform modules are located in the directory \"$firewall_policy_terraform_modules_output_directory\""