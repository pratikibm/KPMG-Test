resource "azurerm_resource_group" "vnet_rg" {
  count    = var.create_resource_group == true ? 1 : 0
  name     = local.rg_name
  location = var.location
  tags     = merge(var.resource_group_tags, var.tags)
}
