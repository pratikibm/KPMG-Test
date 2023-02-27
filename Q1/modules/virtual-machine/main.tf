locals {
  nsg_association_settings = {
    for k, v in var.network_interface_settings :
    k => v.nsg_name_to_link != "" ? azurerm_network_security_group.nsg[v.nsg_name_to_link].id : v.nsg_id_to_link
    if anytrue([v.nsg_name_to_link != null, v.nsg_id_to_link != null]) == true
  }

  ip_configuration_list = flatten([
    for ifn, ifcfg in var.network_interface_settings : [
      for cfgindex in range(length(ifcfg["ip_configuration"])) : {
        (format("%s-%s", ifn, cfgindex)) = ifcfg.ip_configuration[cfgindex]
      }
    ]
  ])

  ip_configuration_map = {
    for i in range(length(local.ip_configuration_list)) :
    keys(local.ip_configuration_list[i])[0] => values(local.ip_configuration_list[i])[0]
  }

  pubip_settings = {
    for name, conf in local.ip_configuration_map :
    name => conf.pubip_settings
    if conf.pubip_settings != null
  }

}

resource "azurerm_availability_set" "vm_as" {
  count                        = var.availability_set_config == null ? 0 : 1
  name                         = "AVSET-${var.vm_hostname}"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = var.availability_set_config.platform_fault_domain_count
  platform_update_domain_count = var.availability_set_config.platform_update_domain_count
  managed                      = var.availability_set_config.managed
  tags                         = merge(var.availability_set_tags, var.tags)
}

resource "azurerm_public_ip" "pip" {
  for_each            = local.pubip_settings
  name                = "PIP-${var.vm_hostname}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = coalesce(each.value["sku"], "Basic")
  allocation_method   = coalesce(each.value["allocation_method"], "Dynamic")
  domain_name_label   = each.value["dns_label"]
  tags                = merge(each.value.tags, var.tags)
}

resource "azurerm_network_security_group" "nsg" {
  for_each            = var.network_security_rules
  name                = "NSG-${var.vm_hostname}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dynamic "security_rule" {
    for_each = each.value
    content {
      name        = security_rule.value["name"]
      description = security_rule.value["description"]
      protocol    = security_rule.value["protocol"]

      source_port_range       = length(security_rule.value["source_port_ranges"]) == 0 ? security_rule.value["source_port_range"] : null
      source_port_ranges      = length(security_rule.value["source_port_ranges"]) == 0 ? null : security_rule.value["source_port_ranges"]
      destination_port_range  = length(security_rule.value["destination_port_ranges"]) == 0 ? security_rule.value["destination_port_range"] : null
      destination_port_ranges = length(security_rule.value["destination_port_ranges"]) == 0 ? null : security_rule.value["destination_port_ranges"]

      source_address_prefix                 = length(security_rule.value["source_address_prefixes"]) == 0 ? security_rule.value["source_address_prefix"] : null
      source_address_prefixes               = length(security_rule.value["source_address_prefixes"]) == 0 ? null : security_rule.value["source_address_prefixes"]
      source_application_security_group_ids = length(security_rule.value["source_application_security_group_ids"]) == 0 ? null : security_rule.value["source_application_security_group_ids"]

      destination_address_prefix                 = length(security_rule.value["destination_address_prefixes"]) == 0 ? security_rule.value["destination_address_prefix"] : null
      destination_address_prefixes               = length(security_rule.value["destination_address_prefixes"]) == 0 ? null : security_rule.value["destination_address_prefixes"]
      destination_application_security_group_ids = length(security_rule.value["destination_application_security_group_ids"]) == 0 ? null : security_rule.value["destination_application_security_group_ids"]

      access    = security_rule.value["access"]
      priority  = security_rule.value["priority"]
      direction = security_rule.value["direction"]
    }
  }
  tags = merge(var.network_security_group_tags, var.tags)
}

resource "azurerm_network_interface" "netinf" {
  for_each                      = var.network_interface_settings
  name                          = "NIC-${var.vm_hostname}-${each.key}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = each.value["enable_accelerated_networking"]
  dns_servers                   = each.value["dns_servers"]

  dynamic "ip_configuration" {
    for_each = {
      for k, v in local.ip_configuration_map :
      k => v if element(split("-", k), 0) == each.key
    }
    content {
      name                          = "ipconfig-${var.vm_hostname}-${ip_configuration.key}"
      subnet_id                     = each.value["pvtip_subnet_id"]
      private_ip_address_allocation = ip_configuration.value["pvtip_address"] == "" ? "Dynamic" : "Static"
      private_ip_address            = ip_configuration.value["pvtip_address"]
      public_ip_address_id          = ip_configuration.value["pubip_settings"] != null ? azurerm_public_ip.pip[ip_configuration.key].id : ip_configuration.value["pubip_address_id"]
      primary                       = element(split("-", ip_configuration.key), 1) == "0" ? true : false
    }
  }

  tags = merge(each.value.tags, var.tags)
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  for_each = local.nsg_association_settings

  network_interface_id      = azurerm_network_interface.netinf[each.key].id
  network_security_group_id = each.value
}

resource "azurerm_storage_account" "vm-sa" {
  count                    = var.boot_diagnostics ? 1 : 0
  name                     = substr("bootdiag${var.vm_hostname}", 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = element(split("_", var.boot_diagnostics_sa_type), 0)
  account_replication_type = element(split("_", var.boot_diagnostics_sa_type), 1)
  tags                     = merge(var.storage_account_tags, var.tags)
}

resource "azurerm_virtual_machine" "vm_linux" {
  name                             = var.vm_hostname
  location                         = var.location
  resource_group_name              = var.resource_group_name
  availability_set_id              = var.availability_set_id != null ? var.availability_set_id : join(",", azurerm_availability_set.vm_as.*.id)
  vm_size                          = var.vm_size
  primary_network_interface_id     = values(azurerm_network_interface.netinf)[0].id
  network_interface_ids            = values(azurerm_network_interface.netinf).*.id
  delete_os_disk_on_termination    = var.delete_os_disk_on_termination
  delete_data_disks_on_termination = var.delete_data_disks_on_termination

  storage_image_reference {
    id        = var.vm_os_id
    publisher = var.vm_os_id == "" ? coalesce(var.vm_os_publisher, local.publisher) : ""
    offer     = var.vm_os_id == "" ? coalesce(var.vm_os_offer, local.offer) : ""
    sku       = var.vm_os_id == "" ? coalesce(var.vm_os_sku, local.sku) : ""
    version   = var.vm_os_id == "" ? coalesce(var.vm_os_version, local.version) : ""
  }

  dynamic "plan" {
    for_each = var.vm_os_simple != "" ? local.plan : var.vm_os_plan
    content {
      name      = plan.key
      product   = plan.value["product"]
      publisher = plan.value["publisher"]
    }
  }

  storage_os_disk {
    name              = "osdisk-${var.vm_hostname}"
    os_type           = "Linux"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = var.storage_account_type
  }

  dynamic "storage_data_disk" {
    for_each = var.data_disk_settings
    content {
      name              = "datadisk-${var.vm_hostname}-${storage_data_disk.key}"
      create_option     = storage_data_disk.value["create_option"]
      lun               = storage_data_disk.value["lun"]
      disk_size_gb      = storage_data_disk.value["size"]
      managed_disk_type = storage_data_disk.value["sa_type"]
    }
  }

  dynamic "os_profile" {
    for_each = var.skip_os_profile ? [] : [1]
    content {
      computer_name  = var.vm_hostname
      admin_username = var.admin_username
      admin_password = var.admin_password
      custom_data    = var.custom_data
    }
  }

  dynamic "os_profile_linux_config" {
    for_each = var.skip_os_profile_linux_config ? [] : [1]
    content {
      #tfsec:ignore:azure-compute-disable-password-authentication
      disable_password_authentication = false
    }
  }

  tags = merge(var.virtual_machine_tags, var.tags)

  boot_diagnostics {
    enabled     = var.boot_diagnostics
    storage_uri = var.boot_diagnostics ? join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint) : ""
  }
}

resource "azurerm_virtual_machine_extension" "this" {
  for_each = var.extensions

  name                       = each.key
  virtual_machine_id         = azurerm_virtual_machine.vm_linux.id
  publisher                  = each.value.publisher
  type                       = each.value.type
  type_handler_version       = each.value.type_handler_version
  auto_upgrade_minor_version = each.value.auto_upgrade_minor_version
  protected_settings         = each.value.protected_settings
  settings                   = each.value.settings
  tags                       = merge(each.value.tags, var.tags)
}
