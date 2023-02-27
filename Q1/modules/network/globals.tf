data "azurerm_subscription" "current" {}
//data.azurerm_subscription.current.display_name looks like CRT.XINFRA.DEV.EASTUS

locals {
  address_space               = replace(var.vnet_address_space[0], "/", "-")
  department                  = split(".", data.azurerm_subscription.current.display_name)[0]
  team                        = split(".", data.azurerm_subscription.current.display_name)[1]
  vnet_name                   = length(var.vnet_name) > 0 ? var.vnet_name : "${local.address_space}-${local.department}-${local.team}"
  rg_name                     = length(var.resource_group_name) > 0 ? var.resource_group_name : "${lower(local.team)}-networking"
  diagnostic_settings_enabled = (var.log_analytics_workspace_id != "" || var.logs_eventhub_name != "" || var.diagnostic_setting_storage_account_id != "") ? true : false
}
