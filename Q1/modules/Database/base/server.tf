resource "azurerm_mssql_server" "server" {
  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.mssql_version
  administrator_login           = var.server_admin_username
  administrator_login_password  = var.server_admin_password
  connection_policy             = var.server_connection_policy
  public_network_access_enabled = var.enable_public_network_access
  minimum_tls_version           = var.minimum_tls_version
  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator[*]
    content {
      login_username = azuread_administrator.value.login_username
      object_id      = azuread_administrator.value.object_id
      tenant_id      = azuread_administrator.value.tenant_id
    }
  }
  identity {
    type = "SystemAssigned"
  }
  tags = merge(var.server_tags, var.tags)
}

resource "azurerm_mssql_server_transparent_data_encryption" "server" {
  depends_on       = [azurerm_mssql_server.server]
  count            = var.enable_data_encryption ? 1 : 0
  server_id        = azurerm_mssql_server.server.id
  key_vault_key_id = var.encryption_key_id
}

resource "azurerm_mssql_server_extended_auditing_policy" "server" {
  depends_on             = [azurerm_mssql_server_transparent_data_encryption.server]
  count                  = local.enable_auditing ? 1 : 0
  server_id              = azurerm_mssql_server.server.id
  log_monitoring_enabled = true
}

data "azurerm_monitor_diagnostic_categories" "diag-category" {
  depends_on  = [azurerm_mssql_server_extended_auditing_policy.server]
  count       = local.enable_auditing ? 1 : 0
  resource_id = local.master_db_id
}

resource "azurerm_monitor_diagnostic_setting" "server" {
  depends_on = [
    azurerm_mssql_server_extended_auditing_policy.server,
    data.azurerm_monitor_diagnostic_categories.diag-category
  ]
  count              = local.enable_auditing ? 1 : 0
  name               = "mssql-server-diagnostic-setting"
  target_resource_id = local.master_db_id

  eventhub_authorization_rule_id = var.auditing.eventhub != null ? var.auditing.eventhub.rule_id : null
  eventhub_name                  = var.auditing.eventhub != null ? var.auditing.eventhub.name : null
  log_analytics_destination_type = var.auditing.log_analytics != null ? var.auditing.log_analytics.destination_type : null
  log_analytics_workspace_id     = var.auditing.log_analytics != null ? var.auditing.log_analytics.workspace_id : null
  storage_account_id             = var.auditing.storage_account != null ? var.auditing.storage_account.id : null
  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.diag-category.0.logs
    content {
      category = log.value
      enabled  = !contains(coalesce(var.auditing.log_types_to_disable, []), log.value)
      retention_policy {
        days    = local.auditing_retention_enabled ? var.auditing.storage_account.retention_days : 0
        enabled = local.auditing_retention_enabled
      }
    }
  }
  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.diag-category.0.metrics
    content {
      category = metric.value
      enabled  = !contains(coalesce(var.auditing.metric_types_to_disable, []), metric.value)
      retention_policy {
        days    = local.auditing_retention_enabled ? var.auditing.storage_account.retention_days : 0
        enabled = local.auditing_retention_enabled
      }
    }
  }
}

resource "azurerm_mssql_virtual_network_rule" "server" {
  for_each                             = { for id in toset(var.allowed_vnets) : reverse(split("/", id))[0] => id }
  name                                 = each.key
  server_id                            = azurerm_mssql_server.server.id
  subnet_id                            = each.value
  ignore_missing_vnet_service_endpoint = true
}

resource "azurerm_mssql_firewall_rule" "server" {
  for_each         = var.firewall_rules
  name             = each.key
  server_id        = azurerm_mssql_server.server.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}