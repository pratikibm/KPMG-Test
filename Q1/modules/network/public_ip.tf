resource "azurerm_public_ip" "pip" {
  depends_on = [azurerm_resource_group.vnet_rg]

  for_each = var.public_ip_settings

  name                    = format("%s-pip", each.key)
  location                = var.location
  resource_group_name     = local.rg_name
  allocation_method       = each.value.allocation_method
  sku                     = each.value.sku
  sku_tier                = each.value.sku_tier
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  zones                   = each.value.zones
  tags                    = merge(each.value.tags, var.tags)
}

resource "azurerm_management_lock" "public-ip" {
  for_each = { for k, v in var.public_ip_settings : k => v if v.suppress_lock != true }

  name       = format("%s-pip-lock", each.key)
  scope      = azurerm_public_ip.pip[each.key].id
  lock_level = "CanNotDelete"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "pip_logs_diagnostic_setting" {
  for_each           = local.diagnostic_settings_enabled ? var.public_ip_settings : {}
  name               = format("%s-diagnostic-setting-logs", azurerm_public_ip.pip[each.key].name)
  target_resource_id = azurerm_public_ip.pip[each.key].id

  log_analytics_workspace_id     = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
  eventhub_name                  = var.eventhub_namespace_authorization_rule_id != "" ? var.logs_eventhub_name : null
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id != "" ? var.eventhub_namespace_authorization_rule_id : null
  storage_account_id             = var.diagnostic_setting_storage_account_id != "" ? var.diagnostic_setting_storage_account_id : null
  log_analytics_destination_type = var.log_analytics_destination_type


  dynamic "log" {
    for_each = ["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports", "DDoSProtectionNotifications"]
    content {
      category = log.value
      enabled  = !contains(var.pip_log_types_to_disable, log.value)
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

resource "azurerm_monitor_diagnostic_setting" "pip_metrics_diagnostic_setting" {
  for_each           = local.diagnostic_settings_enabled && var.pip_metrics_enabled ? var.public_ip_settings : {}
  name               = format("%s-diagnostic-setting-metrics", azurerm_public_ip.pip[each.key].name)
  target_resource_id = azurerm_public_ip.pip[each.key].id

  log_analytics_workspace_id     = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
  eventhub_name                  = var.eventhub_namespace_authorization_rule_id != "" ? var.metrics_eventhub_name : null
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id != "" ? var.eventhub_namespace_authorization_rule_id : null
  storage_account_id             = var.diagnostic_setting_storage_account_id != "" ? var.diagnostic_setting_storage_account_id : null
  log_analytics_destination_type = var.log_analytics_destination_type

  log {
    category = "DDoSMitigationFlowLogs"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "DDoSMitigationReports"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "DDoSProtectionNotifications"
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
