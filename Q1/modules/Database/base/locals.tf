locals {
  master_db_id               = "${azurerm_mssql_server.server.id}/databases/master"
  enable_auditing            = var.auditing.log_analytics != null || var.auditing.eventhub != null || var.auditing.storage_account != null
  auditing_retention_enabled = var.auditing.storage_account != null ? coalesce(var.auditing.storage_account.retention_days, 0) > 0 : false
}