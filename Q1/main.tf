
module "network" {

  source = "./modules/network"

  location            = var.location
  tags                = local.tags
  vnet_address_space  = [var.vnet_address_space]
  resource_group_name = var.resource_group_name
  subnet_settings = {
    web-subnet = {
      address_prefixes = [var.web_subnet_address_prefix]
      lock = {
        level = "CanNotDelete"
        notes = "Subnet Cannot Delete Lock"
      }
    },
    app-subnet = {
      address_prefixes = [var.app_subnet_address_prefix]
      lock = {
        level = "CanNotDelete"
        notes = "Subnet Cannot Delete Lock"
      }
    },
    db-subnet = {
      address_prefixes = [var.db_subnet_address_prefix]
      lock = {
        level = "CanNotDelete"
        notes = "Subnet Cannot Delete Lock"
      }
    }
  }



  nsg_settings = {
    web-subnet = {
      rules = [
        {
          name                       = "ssh-rule-1"
          description                = "Allow ssh connection"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = ["22"]
          source_address_prefix      = "*"
          destination_address_prefix = "*"
          access                     = "Allow"
          priority                   = 101
          direction                  = "Inbound"
        },
        {
          name                       = "ssh-rule-2"
          description                = "Deny ssh connection"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = ["22"]
          source_address_prefixes    = [var.db_subnet_address_prefix]
          destination_address_prefix = "*"
          access                     = "Deny"
          priority                   = 100
          direction                  = "Inbound"
        }
      ]
    },
    app-subnet = {
      rules = [
        {
          name                       = "ssh-rule-1"
          description                = "Allow ssh connection"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = ["22"]
          source_address_prefixes    = [var.web_subnet_address_prefix]
          destination_address_prefix = "*"
          access                     = "Allow"
          priority                   = 100
          direction                  = "Inbound"
        },
        {
          name                       = "ssh-rule-2"
          description                = "Deny ssh connection"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = ["22"]
          source_address_prefixes    = [var.web_subnet_address_prefix]
          destination_address_prefix = "*"
          access                     = "Allow"
          priority                   = 101
          direction                  = "Outbound"
        }
      ]
    },
    db-subnet = {
      rules = [
        {
          name                       = "ssh-rule-1"
          description                = "Allow app subnet connection to db"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = ["8443"]
          source_address_prefixes    = [var.app_subnet_address_prefix]
          destination_address_prefix = "*"
          access                     = "Allow"
          priority                   = 101
          direction                  = "Inbound"
        },
        {
          name                       = "ssh-rule-2"
          description                = ""
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = ["8443"]
          source_address_prefixes    = [var.app_subnet_address_prefix]
          destination_address_prefix = "*"
          access                     = "Allow"
          priority                   = 102
          direction                  = "Outbound"
        },
        {
          name                       = "ssh-rule-3"
          description                = "Deny db connection "
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = ["8443"]
          source_address_prefixes    = [var.web_subnet_address_prefix]
          destination_address_prefix = "*"
          access                     = "Deny"
          priority                   = 100
          direction                  = "Outbound"
        }
      ]
    }
  }

  private_dns_zones = ["privatelink.database.windows.net"]
}



module "database" {
  source = "./modules/Database"

  create_resource_group        = true
  resource_group_name          = var.resource_group_name
  location                     = var.location
  server_admin_password        = local.server_admin_password
  server_admin_username        = local.server_admin_username
  server_name                  = "${var.prefix}-mssql-server"
  enable_public_network_access = false
  # failover_server_location     = "westus"
  tags = local.tags
  auditing = {
    #   log_analytics = {
    #     workspace_id = local.terraform_ci_log_analytics_workspace_id
    #   }
  }
  azuread_administrator = {
    login_username = "terraform-ad"
    object_id      = var.sp_client_id
    tenant_id      = var.tenant_id
  }
  databases = {
    GeneralPurposeGen5 = {
      sku_name = "GP_Gen5_2"
      tags     = local.tags
    }
  }
}

resource "azurerm_private_endpoint" "server" {
  depends_on = [module.database]
  for_each   = module.database.server_ids
  name                = reverse(split("/", each.value))[0]
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = lookup(module.network.subnet_map, "db-subnet")
  private_service_connection {
    is_manual_connection           = false
    name                           = "mssql"
    private_connection_resource_id = each.value
    subresource_names              = ["sqlServer"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [join("/", slice(split("/", lookup(module.network.subnet_map, "db-subnet")), 0, 7), ["privateDnsZones", "privatelink.database.windows.net"])]
  }
  tags = local.tags
}

# wait 5 mins for the pep to be functional
resource "null_resource" "wait-10-min" {
  depends_on = [azurerm_private_endpoint.server]
  provisioner "local-exec" {
    command = "sleep 10m"
  }
}

module "web-vm" {
  depends_on = [
    module.network
  ]
  source = "./modules/virtual-machine"

  vm_count            = 1
  resource_group_name = var.resource_group_name
  location            = var.location
  vm_hostname         = "${var.prefix}webvm"
  network_interface_settings = {
    external = {
      pvtip_subnet_id = lookup(module.network.subnet_map, "web-subnet")
      ip_configuration = [
        {
          pvtip_address = cidrhost(var.web_subnet_address_prefix, 5)
          pubip_settings = {
            sku               = "Basic"
            dns_label         = "host${md5(var.resource_group_name)}"
            allocation_method = "Static"
          }
        },
        {
          pvtip_address = cidrhost(var.web_subnet_address_prefix, 6)
        }
      ]
      # nsg_name_to_link = "nsg-web-subnet"
    }
    internal = {
      pvtip_subnet_id = lookup(module.network.subnet_map, "web-subnet")
      ip_configuration = [
        {
          pvtip_address = ""
        }
      ]
    }
  }

  admin_username                   = "testuser"
  admin_password                   = "Passw0rd"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true


  vm_os_simple = "UbuntuServer"

  data_disk_settings = {
    db = {
      size          = 10
      lun           = 0
      create_option = "Empty"
      sa_type       = "Standard_LRS"
    },
    logs = {

      size          = 20
      lun           = 1
      create_option = "Empty"
      sa_type       = "Standard_LRS"
    }
  }

  availability_set_config = {
    platform_fault_domain_count  = 2
    platform_update_domain_count = 2
    managed                      = true
  }



  extensions = {
    example = {
      publisher            = "Microsoft.Azure.Extensions"
      type                 = "CustomScript"
      type_handler_version = "2.0"
      settings = jsonencode({
        "commandToExecute" = "/bin/ls"
      })
    }
  }

  boot_diagnostics = true
  tags             = local.tags
}

module "app-vm" {
  depends_on = [
    module.network
  ]
  source = "./modules/virtual-machine"

  vm_count            = 1
  resource_group_name = var.resource_group_name
  location            = var.location
  vm_hostname         = "${var.prefix}appvm"
  network_interface_settings = {
    internal = {
      pvtip_subnet_id = lookup(module.network.subnet_map, "web-subnet")
      ip_configuration = [
        {
          pvtip_address = ""
        }
      ]
    }
  }

  admin_username                   = "testuser"
  admin_password                   = "Passw0rd"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true


  vm_os_simple = "UbuntuServer"

  data_disk_settings = {
    db = {
      size          = 10
      lun           = 0
      create_option = "Empty"
      sa_type       = "Standard_LRS"
    },
    logs = {

      size          = 20
      lun           = 1
      create_option = "Empty"
      sa_type       = "Standard_LRS"
    }
  }

  availability_set_config = {
    platform_fault_domain_count  = 2
    platform_update_domain_count = 2
    managed                      = true
  }



  extensions = {
    example = {
      publisher            = "Microsoft.Azure.Extensions"
      type                 = "CustomScript"
      type_handler_version = "2.0"
      settings = jsonencode({
        "commandToExecute" = "/bin/ls"
      })
    }
  }

  boot_diagnostics = true
  tags             = local.tags
}