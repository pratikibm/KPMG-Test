/////////////////////////////
//  ROUTE TABLE RESOURCES  //
/////////////////////////////
resource "azurerm_route_table" "agent_route_table" {
  depends_on = [azurerm_resource_group.vnet_rg]

  for_each            = var.route_settings
  name                = format("rt-%s", each.key)
  location            = var.location
  resource_group_name = local.rg_name
  tags                = merge(each.value.tags, var.tags)

  disable_bgp_route_propagation = each.value.disable_bgp_route_propagation

  #We cannot manage route in this resource since we are adding route outside of this resource
}

resource "azurerm_route" "routes" {
  for_each = merge(
    [for subnet_name, route_table in var.route_settings :
      { for route in route_table.routes : "${subnet_name}-${route.name}" => merge(route, { subnet_name = subnet_name }) }
    ]...
  )

  resource_group_name = local.rg_name
  route_table_name    = azurerm_route_table.agent_route_table[each.value.subnet_name].name

  name                   = each.value["name"]
  address_prefix         = each.value["address_prefix"]
  next_hop_type          = each.value["next_hop_type"]
  next_hop_in_ip_address = each.value["next_hop_type"] == "VirtualAppliance" ? each.value["next_hop_in_ip_address"] : null
}

resource "azurerm_subnet_route_table_association" "agent_rta" {
  for_each       = var.route_settings
  subnet_id      = azurerm_subnet.vnet_subnet[each.key].id
  route_table_id = azurerm_route_table.agent_route_table[each.key].id
}
