output "primary_fqdn" {
  value = module.primary.server_fqdn
}

output "primary_server_id" {
  value = module.primary.server_id
}

output "primary_db_ids" {
  value = module.primary.db_ids
}

output "primary_elastic_pool_ids" {
  value = module.primary.elastic_pool_ids
}

output "secondary_fqdn" {
  value = length(module.secondary) > 0 ? module.secondary.0.server_fqdn : ""
}

output "secondary_server_id" {
  value = length(module.secondary) > 0 ? module.secondary.0.server_id : ""
}

output "secondary_db_ids" {
  value = length(module.secondary) > 0 ? module.secondary.0.db_ids : {}
}

output "secondary_elastic_pool_ids" {
  value = length(module.secondary) > 0 ? module.secondary.0.elastic_pool_ids : {}
}

output "main_entrypoint" {
  value = length(azurerm_mssql_failover_group.failover_group) > 0 ? "${azurerm_mssql_failover_group.failover_group.0.name}.database.windows.net" : module.primary.server_fqdn
}

output "identity" {
  value = {
    primary   = module.primary.identity,
    secondary = length(module.secondary) > 0 ? module.secondary.0.identity : null
  }
}

output "server_ids" {
  value = merge(
    { primary = module.primary.server_id },
    length(module.secondary) > 0 ? { secondary = module.secondary.0.server_id } : null
  )
}

output "server_names" {
  value = merge(
    { primary = module.primary.server_name },
    length(module.secondary) > 0 ? { secondary = module.secondary.0.server_name } : null
  )
}