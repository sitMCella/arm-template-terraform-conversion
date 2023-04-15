#!/bin/bash

# The following script generates the mapping between IP Group variables in the ARM Template and 
# the name of the Terraform variables associated with the Azure IP Groups.
# The current version of the script assumes that all the Azure IP Groups are located in one Subscription.
# The mapping is stored in the CSV file "ip_groups_mapping.csv".

# Requirements:
# - Install Azure CLI
# - Login in Azure:
# az login

search_global=true
subscription_id=""
output_file_name="ip_groups_mapping.csv"

display_help() {
    echo "Usage: $0 [Options]"
    echo "   -s, --search    Search for the IP Groups in a specific Subcription: [subscription_id]"
}

store_ip_group_mapping() {
    ip_group_name=$1
    ip_group_variable_name=${ip_group_name//-/_}
    echo "\"[parameters('ipGroups_${ip_group_variable_name}_externalid')]\";var.${ip_group_variable_name}_id" >> $output_file_name
}

# Check arguments
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
    exit 0
fi
if [ $# -gt 0 ] && ! ([ "$1" == "-s" ] || [ "$1" == "--search" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]); then
    display_help
    exit 1
fi
if ! [ $# -eq 2 ] || ! ([ "$1" == "-s" ] || [ "$1" == "--search" ]); then
    display_help
    exit 1
fi
if [ $# -eq 2 ] && ([ "$1" == "-s" ] || [ "$1" == "--search" ]); then
    search_global=false
    subscription_id="$2"
fi

# Create output file
if [ -f ${output_file_name} ]; then
    echo "Remove the old output file"
    rm $output_file_name
fi
touch $output_file_name

if [ $search_global == false ]; then
    {
        az account set --subscription $subscription_id
    } || {
        exit 1
    }
    ip_groups=$(az network ip-group list)
    # Store the IP Group mapping in the output file
    echo "$ip_groups" | jq -rc .[] |  while IFS='' read ip_group; do
        ip_group_name=$(echo "$ip_group" | jq -rc .name)
        store_ip_group_mapping $ip_group_name
    done
fi
