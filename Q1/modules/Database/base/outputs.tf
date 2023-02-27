output "server_name" {
  value = azurerm_mssql_server.server.name
}

output "server_id" {
  value = azurerm_mssql_server.server.id
}

output "server_fqdn" {
  value = azurerm_mssql_server.server.fully_qualified_domain_name
}

output "db_ids" {
  value = { for db in azurerm_mssql_database.db : db.name => db.id }
}

output "elastic_pool_ids" {
  value = { for pool in azurerm_mssql_elasticpool.elastic-pool : pool.name => pool.id }
}

output "identity" {
  value = azurerm_mssql_server.server.identity[0]
}

output "audit_categories" {
  value = data.azurerm_monitor_diagnostic_categories.diag-category[*]
}