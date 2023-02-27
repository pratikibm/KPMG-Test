variable "vm_count" {
  type        = number
  description = "The quantity of VMs to create."
  default     = 1
}

variable "ip_count" {
  type        = number
  description = "Number of Private IPs to be created."
  default     = 1
}

variable "nic_conf" {
  type = object({
    pvtip_subnet_id               = string
    enable_accelerated_networking = bool
    nsg_name_to_link              = string
  })
  default     = null
  description = "Nic configuration. Defaults to null."
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
}

variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

#tfsec:ignore:general-secrets-no-plaintext-exposure
variable "admin_password" {
  description = "The admin password to be used on the VMSS that will be deployed. The password must meet the complexity requirements of Azure"
  default     = ""
}

variable "admin_username" {
  description = "The admin username of the VM that will be deployed"
  default     = "azureuser"
}

variable "custom_data" {
  description = "The custom data to supply to the machine. This can be used as a cloud-init for Linux systems."
  default     = ""
}

variable "skip_os_profile" {
  type        = string
  description = "(optional) Require to skip os_profile and configuration in case of Special OS/Virtual applicances"
  default     = false
}

variable "skip_os_profile_linux_config" {
  type        = string
  description = "(optional) Require to skip configuration in case of Special OS/Virtual applicances"
  default     = false
}

variable "storage_account_type" {
  description = "Defines the type of storage account to be created. Valid options are Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS."
  default     = "Premium_LRS"
}

variable "availability_set_id" {
  type        = string
  description = "(Optional) The ID of the Availability Set in which the Virtual Machine should exist. Changing this forces a new resource to be created"
  default     = null
}

variable "availability_set_config" {
  type = object({
    platform_fault_domain_count  = number
    platform_update_domain_count = number
    managed                      = bool
  })
  default     = null
  description = "Manages an availability set for virtual machines."
}

variable "network_security_rules" {
  type = map(list(object({
    name                                       = string
    description                                = string
    protocol                                   = string
    source_port_range                          = string
    source_port_ranges                         = list(string)
    destination_port_range                     = string
    destination_port_ranges                    = list(string)
    source_address_prefix                      = string
    source_address_prefixes                    = list(string)
    source_application_security_group_ids      = list(string)
    destination_address_prefix                 = string
    destination_address_prefixes               = list(string)
    destination_application_security_group_ids = list(string)
    access                                     = string
    priority                                   = number
    direction                                  = string
  })))
  default     = {}
  description = <<EOT
    Network Security group (key of map) and network security rules settings. Define map to create one matching to network interface map key.
    e.g.
    network_security_rules = {
      test = [
        {
          name                                       = "allow_ssh"
          description                                = "test allow SSH nsg rule"
          protocol                                   = "Tcp"
          source_address_prefix                      = "10.10.10.0/24"
          source_address_prefixes                    = []
          source_port_range                          = "*"
          source_port_ranges                         = []
          destination_address_prefix                 = "*"
          destination_address_prefixes               = []
          destination_port_range                     = "22"
          destination_port_ranges                    = []
          destination_application_security_group_ids = []
          source_application_security_group_ids      = []
          access                                     = "Allow"
          priority                                   = 100
          direction                                  = "Inbound"
        },
        {
          name                                       = "allow_rdp"
          description                                = "test allow RDP nsg rule"
          protocol                                   = "Tcp"
          source_address_prefix                      = "10.10.10.0/24"
          source_address_prefixes                    = []
          source_port_range                          = "*"
          source_port_ranges                         = []
          destination_address_prefix                 = "*"
          destination_address_prefixes               = []
          destination_port_range                     = "3389"
          destination_port_ranges                    = []
          destination_application_security_group_ids = []
          source_application_security_group_ids      = []
          access                                     = "Allow"
          priority                                   = 101
          direction                                  = "Inbound"
        }
      ]
    }

  Where key:- "test" must be matching to network_interface_settings to assign to it.
EOT
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_DS1_V2"
}

variable "vm_hostname" {
  description = "local name of the VM"
}

# ----
variable "vm_os_simple" {
  description = "Specify UbuntuServer, RHEL, openSUSE-Leap, CentOS, Debian, CoreOS and SLES to get the latest image version of the specified os.  Do not provide this value if a custom value is used for vm_os_publisher, vm_os_offer, and vm_os_sku."
  default     = ""
}
# ---- OR -----
variable "vm_os_id" {
  description = "The resource ID of the image that you want to deploy if you are using a custom image."
  default     = ""
}
# ---- OR -----
variable "vm_os_publisher" {
  description = "The name of the publisher of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = ""
}

variable "vm_os_offer" {
  description = "The name of the offer of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = ""
}

variable "vm_os_sku" {
  description = "The sku of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = ""
}

variable "vm_os_version" {
  description = "The version of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "latest"
}
# ----

variable "vm_os_plan" {
  type = map(object({
    product   = string
    publisher = string
  }))
  default     = {}
  description = "(Optional) Provide purchase plan parameters when using vm_os_id"
}

variable "virtual_machine_tags" {
  type        = map(string)
  default     = {}
  description = "A map of the tags to use for the virtual_machine resource"
}

variable "availability_set_tags" {
  type        = map(string)
  default     = {}
  description = "A map of the tags to use for the availability_set resource"
}

variable "storage_account_tags" {
  type        = map(string)
  default     = {}
  description = "A map of the tags to use for the storage_account resource"
}

variable "network_security_group_tags" {
  type        = map(string)
  default     = {}
  description = "A map of the tags to use for the network_security_group resource"
}

variable "delete_os_disk_on_termination" {
  type        = bool
  default     = false
  description = "Delete OS disk when machine is terminated"
}

variable "delete_data_disks_on_termination" {
  type        = bool
  default     = false
  description = "Delete datadisk when machine is terminated"
}

variable "data_disk_settings" {
  type = map(object({
    size          = number
    sa_type       = string
    create_option = string
    lun           = number
  }))
  default     = {}
  description = <<EOT
  Map of data disks to create data disks, default value {} will not create any data disk
  e.g.
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

EOT
}

variable "boot_diagnostics" {
  type        = bool
  default     = false
  description = "(Optional) Enable or Disable boot diagnostics"
}

variable "boot_diagnostics_sa_type" {
  type        = string
  default     = "Standard_LRS"
  description = "(Optional) Storage account type for boot diagnostics"
}

variable "network_interface_settings" {
  type = map(object({
    pvtip_subnet_id               = string
    enable_accelerated_networking = optional(bool)
    dns_servers                   = optional(list(string))
    enable_ip_forwarding          = optional(bool)
    nsg_name_to_link              = optional(string)
    nsg_id_to_link                = optional(string)
    tags                          = optional(map(string))
    ip_configuration = list(object({
      pvtip_address    = string
      pubip_address_id = optional(string)
      pubip_settings = optional(object({
        sku               = string
        dns_label         = string
        allocation_method = string
        tags              = optional(map(string))
      }))
    }))
  }))
  default     = {}
  description = <<EOT
  List of network interfaces with ip address and subnet information.
  e.g.:
  network_interface_settings = {
    external = {
      pvtip_subnet_id = "/subscriptions/test-sub/resourceGroups/test-subscription/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
      ip_configuration = [
        {
          pvtip_address = "192.168.10.5"
          pubip_settings = {
            sku               = "Basic"
            dns_label         = "dns-label"
            allocation_method = "Static"
          }
        },
        {
          pvtip_address = "" // For Dynamic IP allocation
        }
      ]
      nsg_name_to_link = "default"
    }
  }

  Key:- "test" is name prefix for NIC and linked with matching NSG and Public IP.
EOT
}

variable "extensions" {
  type = map(object({
    publisher                  = string
    type                       = string
    type_handler_version       = string
    auto_upgrade_minor_version = optional(string)
    protected_settings         = optional(string)
    settings                   = optional(string)
    tags                       = optional(map(string))
  }))
  default     = {}
  description = <<EOS
  -------------------------------------
  (Optional)
  A map of maps describing the Virtual Machine extensions.

  The following arguments are supported:
    name                         - (  Key   ) The name for the Virtual Machine Extension. Changing this forces a new resource to be created.
    publisher                    - (Required) Specifies the Publisher of the Extension. Changing this forces a new resource to be created.
    type                         - (Required) Specifies the Type of the Extension. Changing this forces a new resource to be created.
    type_handler_version         - (Required) Specifies the version of the extension to use, available versions can be found using the Azure CLI.
    auto_upgrade_minor_version   - (Optional) Should the latest version of the Extension be used at Deployment Time, if one is available? This won't auto-update the extension on existing installation. Defaults to true.
    protected_settings           - (Optional) A JSON String which specifies Sensitive Settings (such as Passwords) for the Extension.
    TODO: provision_after_extensions   - (Optional) An ordered list of Extension names which this should be provisioned after.
    settings                     - (Optional) A JSON String which specifies Settings for the Extension.
    protected_settings           - (Optional) The protected_settings passed to the extension, like settings, these are specified as a JSON object in a string.
    tags                         - (Optional) A mapping of tags to assign to the resource.

  NOTES
  - The virtual_machine_id should be the ID from the azurerm_linux_virtual_machine or azurerm_windows_virtual_machine resource - when using the older azurerm_virtual_machine resource extensions should instead be defined inline.
  - Keys within the settings block are notoriously case-sensitive, where the casing required (e.g. TitleCase vs snakeCase) depends on the Extension being used. Please refer to the documentation for the specific Virtual Machine Extension you're looking to use for more information.
  - Keys within the protected_settings block are notoriously case-sensitive, where the casing required (e.g. TitleCase vs snakeCase) depends on the Extension being used. Please refer to the documentation for the specific Virtual Machine Extension you're looking to use for more information.

  EXAMPLE
  // Create an extension that will run an executable command as part of instance provisioning/maintenance
  extensions = {
    example = {
      publisher                    = "Microsoft.Azure.Extensions"
      type                         = "CustomScript"
      type_handler_version         = "2.0"
      settings = jsonencode({
        "commandToExecute" = "/bin/ls"
      })
    }
  }
  -------------------------------------
EOS
}
