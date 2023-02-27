locals {
  # databases of certain SKUs cannot be created in secondary mode on secondary server
  # because tests failed. The root cause is TBD.
  secondary_databases = { for k, v in var.databases : k => v if !contains([
    "dw", # DataWarehouse
    "hs", # Hyperscale
  ], substr(lower(v.sku_name), 0, 2)) }
  failover_enabled = var.failover_server_location != ""
}

resource "azurerm_resource_group" "resource_group" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = merge(var.resource_group_tags, var.tags)
}

module "primary" {
  depends_on = [
    azurerm_resource_group.resource_group
  ]
  source = "./base"

  allowed_vnets                = var.allowed_vnets
  auditing                     = var.auditing
  azuread_administrator        = var.azuread_administrator
  databases                    = var.databases
  elastic_pools                = var.elastic_pools
  enable_data_encryption       = var.enable_data_encryption
  enable_public_network_access = var.enable_public_network_access
  encryption_key_id            = var.encryption_key_id
  firewall_rules               = var.firewall_rules
  location                     = var.location
  minimum_tls_version          = var.minimum_tls_version
  mssql_version                = var.mssql_version
  resource_group_name          = var.resource_group_name
  server_admin_password        = var.server_admin_password
  server_admin_username        = var.server_admin_username
  server_connection_policy     = var.server_connection_policy
  server_name                  = coalesce(var.server_names_override.primary_server_name, "${var.server_name}-${var.location}")
  server_tags                  = var.server_tags
  tags                         = var.tags
}

module "secondary" {
  depends_on = [
    azurerm_resource_group.resource_group,
    module.primary
  ]
  source = "./base"
  count  = local.failover_enabled ? 1 : 0

  allowed_vnets                = var.allowed_vnets
  auditing                     = var.auditing
  azuread_administrator        = var.azuread_administrator
  databases                    = var.databases
  db_creation_source_ids       = module.primary.db_ids
  elastic_pools                = var.elastic_pools
  enable_data_encryption       = var.enable_data_encryption
  enable_public_network_access = var.enable_public_network_access
  encryption_key_id            = var.encryption_key_id
  firewall_rules               = var.firewall_rules
  is_secondary                 = var.failover_server_location != ""
  location                     = var.failover_server_location
  minimum_tls_version          = var.minimum_tls_version
  mssql_version                = var.mssql_version
  resource_group_name          = var.resource_group_name
  server_admin_password        = var.server_admin_password
  server_admin_username        = var.server_admin_username
  server_connection_policy     = var.server_connection_policy
  server_name                  = coalesce(var.server_names_override.secondary_server_name, "${var.server_name}-${var.failover_server_location}")
  server_tags                  = var.server_tags
  tags                         = var.tags
}

resource "azurerm_mssql_failover_group" "failover_group" {
  depends_on = [
    module.secondary
  ]
  count     = local.failover_enabled ? 1 : 0
  name      = coalesce(var.server_names_override.failover_endpoint_name, var.server_name)
  server_id = module.primary.server_id
  databases = values(module.primary.db_ids)
  partner_server {
    id = module.secondary.0.server_id
  }
  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = var.failover_grace_minutes
  }
  readonly_endpoint_failover_policy_enabled = true
  tags                                      = merge(var.failover_group_tags, var.tags)
}

