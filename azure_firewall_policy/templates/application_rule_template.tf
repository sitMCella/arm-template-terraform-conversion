        {
          name                  = "${rule_name}"
          source_addresses      = ${source_addresses}
          source_ip_groups      = ${source_ip_groups}
          destination_fqdns     = ${target_fqdns}
          destination_fqdn_tags = ${fqdn_tags}
          protocols = [
            {
              type = "${protocol_type}"
              port = "${protocol_port}"
            }
          ]
