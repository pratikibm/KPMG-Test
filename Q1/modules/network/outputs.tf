output "resourcegroup_name" {
  value = local.rg_name
}

output "location" {
  value = var.location
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

# output "subnet_id" {
#   value = azurerm_subnet.vnet_subnet.*.id
# }

output "subnet_map" {
  value = { for s in azurerm_subnet.vnet_subnet : s.name => s.id }
}

output "nsg_list" {
  value = azurerm_network_security_group.nsg
}

output "nsg_map" {
  value = { for nsg in azurerm_network_security_group.nsg : nsg.name => nsg.id }
}

output "nsg_associations" {
  value = azurerm_subnet_network_security_group_association.nsg_assocation
}

output "private_dns_zone_map" {
  value = { for zone in azurerm_private_dns_zone.private_dns_zone : zone.name => zone.id }
}
