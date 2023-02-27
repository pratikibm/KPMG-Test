output "vm_id" {
  description = "Virtual machine ids created."
  value       = azurerm_virtual_machine.vm_linux.id
}

output "network_security_group_id" {
  description = "id of the security group provisioned"
  value       = values(azurerm_network_security_group.nsg).*.id
}

output "network_security_group_name" {
  description = "name of the security group provisioned"
  value       = values(azurerm_network_security_group.nsg).*.name
}

output "network_interface_ids" {
  description = "ids of the vm nics provisoned."
  value       = values(azurerm_network_interface.netinf).*.id
}

output "network_interface_private_ip" {
  description = "private ip addresses of the vm nics"
  value       = values(azurerm_network_interface.netinf).*.private_ip_address
}

output "public_ip_id" {
  description = "id of the public ip address provisoned."
  value       = [for ip in azurerm_public_ip.pip : ip.id]
}

output "public_ip_address" {
  description = "The actual ip address allocated for the resource."
  value       = [for ip in azurerm_public_ip.pip : ip.ip_address]
}

output "public_ip_dns_name" {
  description = "fqdn to connect to the first vm provisioned."
  value       = [for ip in azurerm_public_ip.pip : ip.fqdn]
}

output "availability_set_id" {
  description = "id of the availability set where the vms are provisioned."
  value       = join(",", azurerm_availability_set.vm_as.*.id)
}
