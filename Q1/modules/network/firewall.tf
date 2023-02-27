resource "azurerm_public_ip" "default_firewall_pip" {
  depends_on = [azurerm_resource_group.vnet_rg]

  count                   = lookup(var.subnet_settings, "AzureFirewallSubnet", null) == null ? 0 : 1
  name                    = "${local.address_space}-default-fw-pip"
  location                = var.location
  resource_group_name     = local.rg_name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 4
  tags                    = merge(var.firewall_public_ip_tags, var.tags)
  zones                   = var.firewall_public_ip_availability_zones
}

resource "azurerm_firewall" "firewall" {
  depends_on = [azurerm_resource_group.vnet_rg]

  count               = lookup(var.subnet_settings, "AzureFirewallSubnet", null) == null ? 0 : 1
  name                = "${local.address_space}-FW"
  location            = var.location
  resource_group_name = local.rg_name
  tags                = merge(var.firewall_tags, var.tags)
  sku_name            = var.firewall_sku_name
  sku_tier            = var.firewall_sku_tier

  #Default IP Conf blocks which requires a Subnet ID
  ip_configuration {
    name                 = "default"
    subnet_id            = azurerm_subnet.vnet_subnet["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.default_firewall_pip.0.id
  }

  dynamic "ip_configuration" {
    for_each = var.firewall_pips
    content {
      name                 = ip_configuration.key
      public_ip_address_id = ip_configuration.value.id
    }
  }
}

resource "azurerm_firewall_nat_rule_collection" "nat_rule_collections" {
  for_each            = lookup(var.subnet_settings, "AzureFirewallSubnet", null) == null ? {} : var.nat_rule_collections
  name                = each.key
  azure_firewall_name = azurerm_firewall.firewall.0.name
  resource_group_name = local.rg_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                  = rule.key
      source_addresses      = rule.value.source_addresses
      destination_ports     = rule.value.destination_ports
      destination_addresses = rule.value.destination_addresses
      translated_address    = rule.value.translated_address
      translated_port       = rule.value.translated_port
      protocols             = rule.value.protocols
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "network_rule_collections" {
  for_each            = lookup(var.subnet_settings, "AzureFirewallSubnet", null) == null ? {} : var.network_rule_collections
  name                = each.key
  azure_firewall_name = azurerm_firewall.firewall.0.name
  resource_group_name = local.rg_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                  = rule.key
      source_addresses      = rule.value.source_addresses
      destination_ports     = rule.value.destination_ports
      destination_addresses = rule.value.destination_addresses
      protocols             = rule.value.protocols
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall_logs_diagnostic_setting" {
  count              = lookup(var.subnet_settings, "AzureFirewallSubnet", null) != null && local.diagnostic_settings_enabled ? 1 : 0
  name               = format("%s-FW-diagnostic-setting-logs", local.address_space)
  target_resource_id = azurerm_firewall.firewall.0.id

  log_analytics_workspace_id     = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
  eventhub_name                  = var.eventhub_namespace_authorization_rule_id != "" ? var.logs_eventhub_name : null
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id != "" ? var.eventhub_namespace_authorization_rule_id : null
  storage_account_id             = var.diagnostic_setting_storage_account_id != "" ? var.diagnostic_setting_storage_account_id : null
  log_analytics_destination_type = var.log_analytics_destination_type

  dynamic "log" {
    for_each = ["AzureFirewallApplicationRule", "AzureFirewallDnsProxy", "AzureFirewallNetworkRule"]
    content {
      category = log.value
      enabled  = !contains(var.fw_log_types_to_disable, log.value)
    }
  }
  metric {
    category = "AllMetrics"
    enabled  = false
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall_metrics_diagnostic_setting" {
  count              = lookup(var.subnet_settings, "AzureFirewallSubnet", null) != null && local.diagnostic_settings_enabled && var.firewall_metrics_enabled ? 1 : 0
  name               = format("%s-FW-diagnostic-setting-metrics", local.address_space)
  target_resource_id = azurerm_firewall.firewall.0.id

  log_analytics_workspace_id     = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
  eventhub_name                  = var.eventhub_namespace_authorization_rule_id != "" ? var.metrics_eventhub_name : null
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id != "" ? var.eventhub_namespace_authorization_rule_id : null
  storage_account_id             = var.diagnostic_setting_storage_account_id != "" ? var.diagnostic_setting_storage_account_id : null
  log_analytics_destination_type = var.log_analytics_destination_type

  log {
    category = "AzureFirewallApplicationRule"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "AzureFirewallDnsProxy"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "AzureFirewallNetworkRule"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
