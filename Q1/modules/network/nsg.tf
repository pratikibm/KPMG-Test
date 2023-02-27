locals {
  /*
  FROM 
  {
    test-public = {
      sku                     = "standard"
      allocation_method       = "Static"
      idle_timeout_in_minutes = 5
      ports_to_exposed_to_internet_on_nsg = {
        test = {
          exposed_ports = ["80", "443"]
          priority      = 3000
        }
      }
      ports_to_exposed_to_nuance_on_nsg = {}
    },
    test-office = {
      sku                                 = "standard"
      allocation_method                   = "Static"
      idle_timeout_in_minutes             = 5
      ports_to_exposed_to_internet_on_nsg = {}
      ports_to_exposed_to_nuance_on_nsg = {
        test = {
          exposed_ports = ["80", "443"]
          priority      = 3500
        }
      }
    },
  }

  TO

  {
    test-public = {
        test = {
          exposed_ports = ["80", "443"]
          priority      = 3000
        }
    },
    test-office = {}
  }
  */
  public_ip_exposed_to_internet_nsg_rules = {
    for pip_name, pip_setting in var.public_ip_settings :
    pip_name => pip_setting.ports_to_exposed_to_internet_on_nsg
    if pip_setting.ports_to_exposed_to_internet_on_nsg != {}
  }

  # This local value isn't actually used.
  # However, if the condition !contains(keys(var.subnet_settings), k) is true, 
  # it will generate an Error: Invalid index,
  # Preventing us from creating public IPs who refer to non-existent NSG settings. 
  public_ip_exposed_to_internet_nsg_rules_validation = {
    for k, v in local.public_ip_exposed_to_internet_nsg_rules : k => {
      for k, x in v :
      k => var.nsg_settings[k]
      if !contains(keys(var.nsg_settings), k)
    }
  }

  /*
  FROM
  {
    test-public = {
        test = {
          exposed_ports = ["80", "443"]
          priority      = 3000
        }
    },
    test-office = {}
  }
  TO
  [ 
    {
      test = [
        {
          name                                       = format("Allow-%s-From-Internet", pip_name)
          description                                = "Allows access to public IP from Internet"
          protocol                                   = "*"
          source_port_range                          = "*"
          source_port_ranges                         = []
          destination_port_range                     = ""
          destination_port_ranges                    = rule_settings.exposed_ports
          source_address_prefix                      = "*"
          source_address_prefixes                    = []
          source_application_security_group_ids      = []
          destination_address_prefix                 = azurerm_public_ip.pip[pip_name].ip_address
          destination_address_prefixes               = []
          destination_application_security_group_ids = []
          access                                     = "Allow"
          priority                                   = rule_settings.priority
          direction                                  = "Inbound"
        }
      ]
    }
  ]
  */

  public_ip_internet_security_rules = flatten([
    for pip_name, ports_to_expose_by_nsg in local.public_ip_exposed_to_internet_nsg_rules : [
      for nsg_name, rule_settings in ports_to_expose_by_nsg : {
        "${nsg_name}" = [
          {
            name                                       = format("Allow-%s-From-Internet", pip_name)
            description                                = "Allows access to public IP from Internet"
            protocol                                   = "*"
            source_port_range                          = "*"
            source_port_ranges                         = []
            destination_port_range                     = ""
            destination_port_ranges                    = rule_settings.exposed_ports
            source_address_prefix                      = "*"
            source_address_prefixes                    = []
            destination_address_prefix                 = azurerm_public_ip.pip[pip_name].ip_address
            destination_address_prefixes               = []
            access                                     = "Allow"
            priority                                   = rule_settings.priority
            direction                                  = "Inbound"
            source_application_security_group_ids      = []
            destination_application_security_group_ids = []
          }
        ]
      }
    ]
  ])

  /*
  FROM 
  {
    test-public = {
      sku                     = "standard"
      allocation_method       = "Static"
      idle_timeout_in_minutes = 5
      ports_to_exposed_to_internet_on_nsg = {
        test = {
          exposed_ports = ["80", "443"]
          priority      = 3000
        }
      }
      ports_to_exposed_to_nuance_on_nsg = {}
    },
    test-office = {
      sku                                 = "standard"
      allocation_method                   = "Static"
      idle_timeout_in_minutes             = 5
      ports_to_exposed_to_internet_on_nsg = {}
      ports_to_exposed_to_nuance_on_nsg = {
        test = {
          exposed_ports = ["80", "443"]
          priority      = 3500
        }
      }
    },
  }

  TO

  {
    test-public = {},
    test-office = {
      test = {
          exposed_ports = ["80", "443"]
          priority      = 3500
        }
    }
  }
  */
  public_ip_exposed_to_nuance_nsg_rules = {
    for pip_name, pip_setting in var.public_ip_settings :
    pip_name => pip_setting.ports_to_exposed_to_nuance_on_nsg
    if pip_setting.ports_to_exposed_to_nuance_on_nsg != {}
  }

  # This local value isn't actually used.
  # However, if the condition !contains(keys(var.subnet_settings), k) is true, 
  # it will generate an Error: Invalid index,
  # Preventing us from creating public IPs who refer to non-existent NSG settings. 
  public_ip_exposed_to_nuance_nsg_rules_validation = {
    for k, v in local.public_ip_exposed_to_nuance_nsg_rules : k => {
      for k, x in v :
      k => var.nsg_settings[k]
      if !contains(keys(var.nsg_settings), k)
    }
  }

  /*
  FROM
  {
    test-public = {},
    test-office = {
      test = {
          exposed_ports = ["80", "443"]
          priority      = 3500
        }
    }
  }
  TO
  [ 
    {
      test = [
        {
          name                                       = format("Allow-%s-From-Nuance-Offices", pip_name)
          description                                = format("Allows access to public IP from Nuance Offices")
          protocol                                   = "*"
          source_port_range                          = "*"
          source_port_ranges                         = []
          destination_port_range                     = ""
          destination_port_ranges                    = rule_settings.exposed_ports
          source_address_prefix                      = "*"
          source_address_prefixes                    = values(var.nuance_office_outbound_ips)
          source_application_security_group_ids      = []
          destination_address_prefix                 = azurerm_public_ip.pip[pip_name].ip_address
          destination_address_prefixes               = []
          destination_application_security_group_ids = []
          access                                     = "Allow"
          priority                                   = rule_settings.priority
          direction                                  = "Inbound"
        }
      ]
    }
  ]
  */
  public_ip_nuance_office_security_rules = flatten([
    for pip_name, ports_to_expose_by_nsg in local.public_ip_exposed_to_nuance_nsg_rules : [
      for nsg_name, rule_settings in ports_to_expose_by_nsg : {
        "${nsg_name}" = [
          {
            name                       = format("Allow-%s-From-Nuance-Offices", pip_name)
            description                = format("Allows access to public IP from Nuance Offices")
            protocol                   = "*"
            source_port_range          = "*"
            destination_port_ranges    = rule_settings.exposed_ports
            source_address_prefix      = "*"
            source_address_prefixes    = values(var.nuance_office_outbound_ips)
            destination_address_prefix = azurerm_public_ip.pip[pip_name].ip_address
            access                     = "Allow"
            priority                   = rule_settings.priority
            direction                  = "Inbound"
          }
        ]
      }
    ]
  ])

  # This allows additional custom NSG rules on the PIP that we might not want to
  # expose on public Internet or needs special filtering.
  # Without this we would not be able to use the nsg_setting var because we would
  # not know the actual IP address before it's created
  public_ip_additional_nsg_rules = merge([
    for pip_name, pip_setting in var.public_ip_settings : pip_setting.additional_nsg_rules == null ? {} : {
      for rule_name, rule in pip_setting.additional_nsg_rules :
      format("%s-%s", pip_name, rule_name) => {
        name                                       = rule_name
        description                                = rule.description
        protocol                                   = coalesce(rule.protocol, "*")
        source_port_range                          = coalesce(rule.source_port_range, "*")
        source_port_ranges                         = coalesce(rule.source_port_ranges, [])
        destination_port_range                     = rule.destination_port_ranges != null ? "" : coalesce(rule.destination_port_range, "*") # This needs to be "" if destination_port_ranges is set
        destination_port_ranges                    = coalesce(rule.destination_port_ranges, [])
        source_address_prefix                      = rule.source_address_prefixes != null ? "" : coalesce(rule.source_address_prefix, "*") # This needs to be "" if source_address_prefix is set
        source_address_prefixes                    = coalesce(rule.source_address_prefixes, [])
        source_application_security_group_ids      = coalesce(rule.source_application_security_group_ids, [])
        destination_address_prefix                 = azurerm_public_ip.pip[pip_name].ip_address
        destination_address_prefixes               = []
        destination_application_security_group_ids = []
        access                                     = coalesce(rule.access, "Allow")
        priority                                   = rule.priority
        direction                                  = coalesce(rule.direction, "Inbound")
        subnets                                    = rule.subnets
      }
    }
  ]...)

  # This value is just to validate all rules refer to valid subnets
  public_ip_additional_nsg_rulesvalidation = concat([], [
    for pip_name, pip_setting in var.public_ip_settings : pip_setting.additional_nsg_rules == null ? [] : concat([], [
      for rule_name, rule in pip_setting.additional_nsg_rules : [
        for subnet in rule.subnets : var.nsg_settings[subnet] # IF YOU SEE THIS ERROR, CHECK THAT YOU SPECIFIED THE RIGHT SUBNETS IN additional_nsg_rules!!!
      ]
    ]...)
  ]...)
}

resource "azurerm_network_security_group" "nsg" {
  depends_on = [azurerm_resource_group.vnet_rg]

  for_each            = var.nsg_settings
  name                = format("nsg-%s", each.key)
  location            = var.location
  resource_group_name = local.rg_name
  tags                = merge(each.value.tags, var.tags)

  dynamic "security_rule" {
    for_each = concat(
      each.value.rules,
      flatten([for rules in local.public_ip_internet_security_rules : rules[each.key] if contains(keys(rules), each.key)]),
      flatten([for rules in local.public_ip_nuance_office_security_rules : rules[each.key] if contains(keys(rules), each.key)]),
      flatten([for rule in local.public_ip_additional_nsg_rules : rule if contains(rule.subnets, each.key)]),
    )
    content {
      name        = security_rule.value["name"]
      description = security_rule.value["description"]
      protocol    = security_rule.value["protocol"]

      source_port_range       = lookup(security_rule.value, "source_port_range", null)
      source_port_ranges      = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_range  = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges = lookup(security_rule.value, "destination_port_ranges", null)

      source_address_prefix                 = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes               = lookup(security_rule.value, "source_address_prefixes", null)
      source_application_security_group_ids = lookup(security_rule.value, "source_application_security_group_ids", null)

      destination_address_prefix                 = lookup(security_rule.value, "destination_address_prefix", null)
      destination_address_prefixes               = lookup(security_rule.value, "destination_address_prefixes", null)
      destination_application_security_group_ids = lookup(security_rule.value, "destination_application_security_group_ids", null)

      access    = security_rule.value["access"]
      priority  = security_rule.value["priority"]
      direction = security_rule.value["direction"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assocation" {
  for_each                  = var.nsg_settings
  subnet_id                 = azurerm_subnet.vnet_subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

resource "azurerm_monitor_diagnostic_setting" "nsg_logs_diagnostic_setting" {
  for_each           = local.diagnostic_settings_enabled && var.nsg_diagnostic_log_enabled ? var.nsg_settings : {}
  name               = format("%s-diagnostic-setting", azurerm_network_security_group.nsg[each.key].name)
  target_resource_id = azurerm_network_security_group.nsg[each.key].id

  log_analytics_workspace_id     = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
  eventhub_name                  = var.eventhub_namespace_authorization_rule_id != "" ? var.logs_eventhub_name : null
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id != "" ? var.eventhub_namespace_authorization_rule_id : null
  storage_account_id             = var.diagnostic_setting_storage_account_id != "" ? var.diagnostic_setting_storage_account_id : null
  log_analytics_destination_type = var.log_analytics_destination_type

  log {
    category = "NetworkSecurityGroupEvent"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "NetworkSecurityGroupRuleCounter"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}


resource "azurerm_network_watcher_flow_log" "nsg_flow_log" {
  for_each             = var.nsg_flow_enabled ? azurerm_network_security_group.nsg : {}
  name                 = "NetworkWatcherFlowLog_${var.location}" # Network watcher flow log name
  network_watcher_name = "NetworkWatcher_${var.location}"        # Network watcher is already created by vnet
  resource_group_name  = "NetworkWatcherRG"                      # has to be the same as the network watcher's

  network_security_group_id = each.value.id
  storage_account_id        = var.nsg_flow_sa_id
  enabled                   = true
  tags                      = merge(each.value.tags, var.tags)

  retention_policy {
    enabled = true
    days    = var.nsg_flow_retention
  }
}