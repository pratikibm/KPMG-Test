/////////////////////////////////
//  VIRTUAL NETWORK RESOURCES  //
/////////////////////////////////
resource "azurerm_virtual_network" "vnet" {
  depends_on = [azurerm_resource_group.vnet_rg]

  name                = local.vnet_name
  location            = var.location
  resource_group_name = local.rg_name
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [var.ddos_protection_plan_id] : []
    content {
      id     = ddos_protection_plan.value
      enable = true
    }
  }
}

resource "azurerm_subnet" "vnet_subnet" {
  for_each = var.subnet_settings

  name                                          = each.key
  resource_group_name                           = local.rg_name
  address_prefixes                              = each.value.address_prefixes
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  service_endpoints                             = distinct(concat(var.all_subnets_service_endpoints, coalesce(each.value.service_endpoints, [])))
  private_link_service_network_policies_enabled = coalesce(each.value.private_link_service_network_policies_enabled, false)
  private_endpoint_network_policies_enabled     = coalesce(each.value.private_link_service_network_policies_enabled, false)
  dynamic "delegation" {
    for_each = each.value.delegate == null ? [] : [each.value.delegate]
    content {
      name = replace(each.value.delegate.name, "/", ".")
      service_delegation {
        name    = each.value.delegate.name
        actions = each.value.delegate.actions
      }
    }
  }
}

resource "azurerm_management_lock" "subnet" {
  for_each = var.azurerm_lock_enabled ? { for key, value in var.subnet_settings : key => value.lock if value.lock != null } : {}

  name       = format("%s-lock", each.key)
  scope      = azurerm_subnet.vnet_subnet[each.key].id
  lock_level = each.value.level
  notes      = each.value.notes
}

resource "azurerm_monitor_diagnostic_setting" "vnet_logs_diagnostic_setting" {
  count              = local.diagnostic_settings_enabled && var.vnet_diagnostic_log_enabled ? 1 : 0
  name               = format("%s-%s-%s-diagnostic-setting", local.address_space, local.department, local.team)
  target_resource_id = azurerm_virtual_network.vnet.id

  log_analytics_workspace_id     = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
  eventhub_name                  = var.eventhub_namespace_authorization_rule_id != "" ? var.logs_eventhub_name : null
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id != "" ? var.eventhub_namespace_authorization_rule_id : null
  storage_account_id             = var.diagnostic_setting_storage_account_id != "" ? var.diagnostic_setting_storage_account_id : null
  log_analytics_destination_type = var.log_analytics_destination_type

  log {
    category = "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "vnet_metrics_diagnostic_setting" {
  count              = local.diagnostic_settings_enabled && var.vnet_metrics_enabled ? 1 : 0
  name               = format("%s-%s-%s-diagnostic-setting-metrics", local.address_space, local.department, local.team)
  target_resource_id = azurerm_virtual_network.vnet.id

  log_analytics_workspace_id     = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
  eventhub_name                  = var.eventhub_namespace_authorization_rule_id != "" ? var.metrics_eventhub_name : null
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id != "" ? var.eventhub_namespace_authorization_rule_id : null
  storage_account_id             = var.diagnostic_setting_storage_account_id != "" ? var.diagnostic_setting_storage_account_id : null
  log_analytics_destination_type = var.log_analytics_destination_type

  log {
    category = "VMProtectionAlerts"
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
