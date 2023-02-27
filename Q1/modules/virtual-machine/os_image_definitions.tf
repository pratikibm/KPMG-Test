locals {
  standard_os = {
    UbuntuServer = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
      plan      = {}
    },
    RHEL = {
      publisher = "RedHat",
      offer     = "RHEL",
      sku       = "7.7"
      version   = "latest"
      plan      = {}
    },
    openSUSE-Leap = {
      publisher = "SUSE"
      offer     = "openSUSE-Leap"
      sku       = "42.3"
      version   = "latest"
      plan      = {}
    },
    CentOS = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7.7"
      version   = "latest"
      plan      = {}
    },
    Debian = {
      publisher = "credativ"
      offer     = "Debian"
      sku       = "9"
      version   = "latest"
      plan      = {}
    },
    CoreOS = {
      publisher = "CoreOS"
      offer     = "CoreOS"
      sku       = "Stable"
      version   = "latest"
      plan      = {}
    },
    SLES = {
      publisher = "SUSE"
      offer     = "SLES"
      sku       = "12-SP4"
      version   = "latest"
      plan      = {}
    },
    audiocodes-sbc = {
      publisher = "audiocodes"
      offer     = "mediantsessionbordercontroller"
      sku       = "mediantvirtualsbcazure"
      version   = "latest"
      plan = {
        mediantvirtualsbcazure = {
          product   = "mediantsessionbordercontroller"
          publisher = "audiocodes"
        }
      }

    }
  }
  publisher = var.vm_os_simple != "" ? local.standard_os[var.vm_os_simple].publisher : ""
  offer     = var.vm_os_simple != "" ? local.standard_os[var.vm_os_simple].offer : ""
  sku       = var.vm_os_simple != "" ? local.standard_os[var.vm_os_simple].sku : ""
  version   = var.vm_os_simple != "" ? local.standard_os[var.vm_os_simple].version : ""
  plan      = var.vm_os_simple != "" ? local.standard_os[var.vm_os_simple].plan : {}
}