
resource "azurerm_private_dns_zone" "private_dns_zone" {
  depends_on = [azurerm_resource_group.vnet_rg]

  for_each = var.create_private_dns_zones == true ? toset(var.private_dns_zones) : []

  name                = each.value
  resource_group_name = local.rg_name
  tags                = merge(var.private_dns_zone_tags, var.tags)
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_link" {
  depends_on = [azurerm_private_dns_zone.private_dns_zone]

  for_each = toset(var.private_dns_zones)

  name                  = lower(azurerm_virtual_network.vnet.name)
  private_dns_zone_name = each.value
  resource_group_name   = local.rg_name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = merge(var.private_dns_zone_virtual_network_link_tags, var.tags)
}
