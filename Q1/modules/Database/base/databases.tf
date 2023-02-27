resource "azurerm_mssql_elasticpool" "elastic-pool" {
  depends_on = [
    azurerm_mssql_server.server,
    azurerm_mssql_server_transparent_data_encryption.server,
    azurerm_monitor_diagnostic_setting.server
  ]
  for_each            = var.elastic_pools
  name                = each.key
  resource_group_name = azurerm_mssql_server.server.resource_group_name
  location            = azurerm_mssql_server.server.location
  server_name         = azurerm_mssql_server.server.name
  max_size_gb         = each.value.max_size_gb
  sku {
    name     = each.value.sku.name
    capacity = each.value.sku.capacity
    tier     = each.value.sku.tier
    family   = each.value.sku.family
  }
  per_database_settings {
    min_capacity = each.value.min_capacity_per_db
    max_capacity = each.value.max_capacity_per_db
  }
  zone_redundant = each.value.enable_zone_redundant
  tags           = merge(each.value.tags, var.tags)
}

resource "azurerm_mssql_database" "db" {
  depends_on = [
    azurerm_mssql_server.server,
    azurerm_mssql_server_transparent_data_encryption.server,
    azurerm_monitor_diagnostic_setting.server,
    azurerm_mssql_elasticpool.elastic-pool,
  ]
  for_each                    = var.databases
  name                        = each.key
  server_id                   = azurerm_mssql_server.server.id
  auto_pause_delay_in_minutes = each.value.auto_pause_delay_in_minutes
  create_mode                 = var.is_secondary ? "Secondary" : "Default"
  creation_source_database_id = var.is_secondary ? var.db_creation_source_ids[each.key] : null
  collation                   = each.value.collation
  elastic_pool_id             = each.value.elastic_pool_name == null ? null : azurerm_mssql_elasticpool.elastic-pool[each.value.elastic_pool_name].id
  geo_backup_enabled          = each.value.enable_geo_backup
  dynamic "short_term_retention_policy" {
    for_each = each.value.short_term_retention_days[*]
    content {
      retention_days = each.value.short_term_retention_days
    }
  }
  dynamic "long_term_retention_policy" {
    for_each = each.value.long_term_retention_policy[*]
    content {
      weekly_retention  = each.value.long_term_retention_policy.weekly_retention
      monthly_retention = each.value.long_term_retention_policy.monthly_retention
      yearly_retention  = each.value.long_term_retention_policy.yearly_retention
      week_of_year      = each.value.long_term_retention_policy.week_of_year
    }
  }
  max_size_gb          = var.is_secondary ? null : each.value.max_size_gb
  min_capacity         = each.value.min_capacity
  read_replica_count   = each.value.read_replica_count
  read_scale           = var.is_secondary ? null : each.value.enable_read_scale
  sku_name             = each.value.elastic_pool_name == null ? each.value.sku_name : var.is_secondary ? null : "ElasticPool"
  storage_account_type = each.value.backup_storage_redundancy_type
  zone_redundant       = each.value.elastic_pool_name == null ? each.value.enable_zone_redundant : null
  tags                 = merge(each.value.tags, var.tags)
  timeouts {
    create = "3h"
    update = "3h"
    delete = "3h"
  }
}
