variable "create_resource_group" {
  type        = bool
  description = "decides if a new resource group should be created for the neworking resources"
  default     = true
}

variable "create_private_dns_zones" {
  type        = bool
  description = "decides if the private_dns_zones should be created or simply reused and linked"
  default     = true
}

variable "resource_group_name" {
  type        = string
  description = "(Optional) define a custom resource group name"
  default     = ""
}

variable "vnet_name" {
  type        = string
  description = "(Optional) define a custom VNet name"
  default     = ""
}

variable "location" {
  description = "The azure datacenter to deploy the resources to. (e.g: eastus2)"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "The address space that is used the virtual network. You can supply more than one address space"
}

variable "ddos_protection_plan_id" {
  type        = string
  description = "DDOS protection plan object used by the VNET resource"
  default     = null
}

variable "subnet_settings" {
  type = map(object({
    address_prefixes                              = list(string)
    private_link_service_network_policies_enabled = optional(bool)
    private_endpoint_network_policies_enabled     = optional(bool)
    service_endpoints                             = optional(list(string))
    lock = optional(object({
      level = string
      notes = string
    }))
    delegate = optional(object({
      name    = string
      actions = list(string)
    }))
  }))
  description = <<EOS
    A map of subnet settings.
      - key: name of the subnet (If the Name is "AzureFirewallSubnet" a FireWall will be created and attached to the Subnet)
      - value: object
          - address_prefixes: A list of prefixes of the subnet addresses. Example "10.3.128.0/24"
          - private_link_service_network_policies_enabled: to enable private link service policies (to support private links). Enabled by default.
          - private_endpoint_network_policies_enabled: to enable private link endpoint policies (to support private endpoints) Enabled by default.
          - service_endpoints: (Optional) A list of Service Endpoints specific to this subnet. Refer to the "subnets_service_endpoints" variable documentation for general endpoints settings.
          - lock: (Optional) Create azure resource lock for the subnet. Set var.azurerm_lock_enabled to false and don't set this to omit.
            - level:
              The type of lock that will be applied to the subnet to prevent accidential change.
              Possible values are CanNotDelete and ReadOnly.
              CanNotDelete means authorized users are able to read and modify the resources, but not delete.
              ReadOnly means authorized users can only read from a resource, but they can't modify or delete it.
              Default to be ReadOnly.
            - notes: Specifies some notes about the lock. Maximum of 512 characters.
          - delegate:
            - delegate.name:   (Optional) The name of service to delegate to. Possible values include Microsoft.ApiManagement/service, Microsoft.AzureCosmosDB/clusters, Microsoft.BareMetal/AzureVMware, Microsoft.BareMetal/CrayServers, Microsoft.Batch/batchAccounts, Microsoft.ContainerInstance/containerGroups, Microsoft.Databricks/workspaces, Microsoft.DBforMySQL/flexibleServers, Microsoft.DBforMySQL/serversv2, Microsoft.DBforPostgreSQL/flexibleServers, Microsoft.DBforPostgreSQL/serversv2, Microsoft.DBforPostgreSQL/singleServers, Microsoft.HardwareSecurityModules/dedicatedHSMs, Microsoft.Kusto/clusters, Microsoft.Logic/integrationServiceEnvironments, Microsoft.MachineLearningServices/workspaces, Microsoft.Netapp/volumes, Microsoft.Network/managedResolvers, Microsoft.PowerPlatform/vnetaccesslinks, Microsoft.ServiceFabricMesh/networks, Microsoft.Sql/managedInstances, Microsoft.Sql/servers, Microsoft.StreamAnalytics/streamingJobs, Microsoft.Synapse/workspaces, Microsoft.Web/hostingEnvironments, and Microsoft.Web/serverFarms.
            - delegate.actions: (Optional) A list of Actions which should be delegated. Set to [] to omit.
                                This list is specific to the service to delegate to. See https://docs.microsoft.com/en-us/cli/azure/network/vnet/subnet?view=azure-cli-latest#az_network_vnet_subnet_list_available_delegations for all delegations
                                Possible values include Microsoft.Network/networkinterfaces/*, Microsoft.Network/virtualNetworks/subnets/action, Microsoft.Network/virtualNetworks/subnets/join/action, Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action and Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action.
    Example:
      subnet_settings = {
        mysubnetname = {
          address_prefix = "0.0.0.0/0"
          lock = {
            level = "CanNotDelete"
            notes = "Default Subnet Cannot Delete Lock"
          }
        },
      }
EOS
}

variable "route_settings" {
  type = map(object({
    disable_bgp_route_propagation = bool
    routes = list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = string
    }))
    tags = optional(map(string))
  }))
  default     = {}
  description = <<EOS
  A map of configuration for routes.
    - key: name of the subnet for this route table where it should be associated too
    - value: object
      - disable_bgp_route_propagation: Boolean flag which controls propagation of routes learned by BGP on that route table. True means disable.
      - routes [ {
        - name:  The name of the route.
        - address_prefix:  The destination CIDR to which the route applies, such as 10.1.0.0/16
        - next_hop_type: The type of Azure hop the packet should be sent to. Possible values are VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None.
        - next_hop_in_ip_address: Contains the IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance.
      }]
  Example:
    customervoip = {
      disable_bgp_route_propagation = false
      routes = [
        {
          name                   = "default"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.14.41.132"
        },
      ]
    }
EOS
}

variable "nsg_settings" {
  type = map(object({
    rules = list(object({
      name                                       = string
      description                                = string
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(list(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(list(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string))
      source_application_security_group_ids      = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
      access                                     = string
      priority                                   = number
      direction                                  = string
    }))
    tags = optional(map(string))
  }))
  default = {}
  validation {
    condition = length(flatten([
      for o in var.nsg_settings : distinct([
        for rule in o.rules : rule.priority
      ])
    ])) == length(flatten([for o in var.nsg_settings : [for rule in o.rules : rule]]))
    error_message = "Priorities should be unique across the same set of rules."
  }
  validation {
    condition = (alltrue(flatten([
      for o in var.nsg_settings : [
        for rule in o.rules : can(
          (rule.priority > 100) && (rule.priority < 4096)
        )
      ]
    ])))
    error_message = "Rules priority must be within 100 and 4096 (included)."
  }
  validation {
    condition = (alltrue(flatten([
      for o in var.nsg_settings : [
        for rule in o.rules : can(
          contains(["Tcp", "Udp", "Icmp", "*"], rule.protocol)
        )
      ]
    ])))
    error_message = "Protocol should be one of Tcp, Udp, Icmp, or *."
  }
  validation {
    condition = (alltrue(flatten([
      for o in var.nsg_settings : [
        for rule in o.rules : can(
          length(rule.description) < 140
        )
      ]
    ])))
    error_message = "Rules descriptions can't be over 140 characters."
  }
  validation {
    condition = (alltrue(flatten([
      for o in var.nsg_settings : [
        for rule in o.rules : can(
          contains(["Allow", "Deny"], rule.access)
        )
      ]
    ])))
    error_message = "Rules access must be either Allow or Deny."
  }
  validation {
    condition = (alltrue(flatten([
      for o in var.nsg_settings : [
        for rule in o.rules : !(rule.source_port_range == null && rule.source_port_ranges == null) && !(rule.source_port_range != null && rule.source_port_ranges != null)
      ]
    ])))
    error_message = "Define one between source_port_range and source_port_ranges."
  }
  validation {
    condition = (alltrue(flatten([
      for o in var.nsg_settings : [
        for rule in o.rules : !(rule.destination_port_range == null && rule.destination_port_ranges == null) && !(rule.destination_port_range != null && rule.destination_port_ranges != null)
      ]
    ])))
    error_message = "Define one between destination_port_range and destination_port_ranges."
  }
  validation {
    condition = (alltrue(flatten([
      for o in var.nsg_settings : [
        for rule in o.rules : !(rule.source_address_prefix == null && rule.source_address_prefixes == null) && !(rule.source_address_prefix != null && rule.source_address_prefixes != null)
      ]
    ])))
    error_message = "Define one between source_address_prefix and source_address_prefixes."
  }
  validation {
    condition = (alltrue(flatten([
      for o in var.nsg_settings : [
        for rule in o.rules : !(rule.destination_address_prefix == null && rule.destination_address_prefixes == null) && !(rule.destination_address_prefix != null && rule.destination_address_prefixes != null)
      ]
    ])))
    error_message = "Define one between destination_address_prefix and destination_address_prefixes."
  }
  description = <<EOS
  A map of configuration for nsg security rules.
  Required Keys:
    - key: name of the subnet for this nsg where it should be associted too
    - value: object
      - rules [{
        - (Required) name: The name of the security rule.
        - (Required) description: A description for this rule. Restricted to 140 characters.
        - (Required) protocol: Network protocol this rule applies to. Can be Tcp, Udp, Icmp, or * to match all.
        - (Optional) source_port_range: Source Port or Range. Integer or range between 0 and 65535 or * to match any. This is required if source_port_ranges is not specified.
        - (Optional) source_port_ranges: List of source ports or port ranges, note that "*" is not supported. This is required if source_port_range is not specified.
        - (Optional) destination_port_range: Destination Port or Range. Integer or range between 0 and 65535 or * to match any. This is required if destination_port_ranges is not specified.
        - (Optional) destination_port_ranges:  List of destination ports or port ranges, note that "*" is not supported. This is required if destination_port_range is not specified.
        - (Optional) source_address_prefix:  CIDR or source IP range or * to match any IP. Tags such as ‘VirtualNetwork’, ‘AzureLoadBalancer’ and ‘Internet’ can also be used. This is required if source_address_prefixes is not specified.
        - (Optional) source_address_prefixes: List of source address prefixes, note that "*" is not supported. Tags may not be used. This is required if source_address_prefix is not specified.
        - (Optional) source_application_security_group_ids: A List of source Application Security Group ID's
        - (Optional) destination_address_prefix: CIDR or destination IP range or * to match any IP. Tags such as ‘VirtualNetwork’, ‘AzureLoadBalancer’ and ‘Internet’ can also be used. This is required if destination_address_prefixes is not specified.
        - (Optional) destination_address_prefixes: List of destination address prefixes, note that "*" is not supported. Tags may not be used. This is required if destination_address_prefix is not specified.
        - (Optional) destination_application_security_group_ids: A List of destination Application Security Group ID's
        - (Required) access: Specifies whether network traffic is allowed or denied. Possible values are Allow and Deny.
        - (Required) priority: Specifies the priority of the rule. The value can be between 100 and 4096. The priority number must be unique for each rule in the collection. The lower the priority number, the higher the priority of the rule.
        - (Required) direction: The direction specifies if rule will be evaluated on incoming or outgoing traffic. Possible values are Inbound and Outbound.
      }]
  Example:
    management = {
      rules = [
        {
          name                                       = "IB-DenyAll"
          description                                = "Deny all connections into the management subnet"
          protocol                                   = "Tcp"
          source_port_range                          = "*"
          source_port_ranges                         = []
          destination_port_range                     = "*"
          destination_port_ranges                    = []
          source_address_prefix                      = "*"
          source_address_prefixes                    = []
          destination_address_prefix                 = "*"
          destination_address_prefixes               = []
          access                                     = "Deny"
          priority                                   = 4000
          direction                                  = "Inbound"
          source_application_security_group_ids      = []
          destination_application_security_group_ids = []
        },
      ]
    }
EOS
}

variable "public_ip_settings" {
  type = map(object({
    sku                     = string
    sku_tier                = optional(string)
    allocation_method       = string
    idle_timeout_in_minutes = number
    ports_to_exposed_to_internet_on_nsg = map(object({
      exposed_ports = list(string)
      priority      = number
    }))
    ports_to_exposed_to_nuance_on_nsg = map(object({
      exposed_ports = list(string)
      priority      = number
    }))
    additional_nsg_rules = optional(map(object({
      description             = string
      protocol                = optional(string)       # Def: "*" | Valid: Tcp Udp Icmp Ah Esp
      source_port_range       = optional(string)       # "*"
      source_port_ranges      = optional(list(string)) # []
      destination_port_range  = optional(string)       # "*"
      destination_port_ranges = optional(list(string)) # []
      source_address_prefix   = optional(string)       # "*"
      # (Optional) CIDR or source IP range or * to match any IP. Tags such as ‘VirtualNetwork’, ‘AzureLoadBalancer’ and ‘Internet’ can also be used.
      source_address_prefixes               = optional(list(string)) # []
      source_application_security_group_ids = optional(list(string)) # []
      access                                = optional(string)       # Def: "Allow" | "Deny"
      priority                              = string
      direction                             = optional(string) # Def: "Inbound" | "Outbound"
      subnets                               = list(string)
    })))
    zones         = optional(list(string))
    tags          = optional(map(string))
    suppress_lock = optional(bool) # Mainly (only?) useful for tests
  }))
  default     = {}
  description = <<EOS
  A map of configuration setting for public ips.
  Keys:
    - key: name of the public IP
    - value: settings
      - (Required) sku: The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic
      - (Optional) sku_tier: The SKU Tier that should be used for the Public IP. Possible values are Regional and Global. Forces recreation. Defaults to Regional. When sku_tier is set to Global, sku must be set to Standard.
      - (Required) allocation_method: Defines the allocation method for this IP address. Possible values are Static or Dynamic.
      - (Required) idle_timeout_in_minutes: Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes.
      - (Required) ports_to_exposed_to_internet_on_nsg: Map with key matching the subnet name and value for setting a list of ports to exposed on the internet and the priority of the rule.
      - (Required) ports_to_exposed_to_nuance_on_nsg: Map with key matching the subnet name and value for setting a list of ports to exposed on the nuance office and the priority of the rule.
      - (Optional) additional_nsg_rules: Map of extre NSG rules to be added to the subnets specified in the body, for the IP that will be created. See definition for the actual properties.
      - (Optional) zones: A collection containing the availability zone to allocate the Public IP in. Possible values ["1"], ["2"], ["3"], ["1","2","3"] and null. Default is not zone-redundant.
                          Availability Zones are only supported with a Standard SKU and in select regions at this time. Standard SKU Public IP Addresses that do not specify a zone are not zone-redundant by default.
  Example:
    public_ip_settings = {
      gatekeeper-web = {
        sku                     = "standard"
        allocation_method       = "Static"
        idle_timeout_in_minutes = 5
        ports_to_exposed_to_internet_on_nsg = {}
        ports_to_exposed_to_nuance_on_nsg = {}
      },
      global-auth = {
        sku                     = "standard"
        sku_tier                = "Global"
        allocation_method       = "Static"
        idle_timeout_in_minutes = 5
        ports_to_exposed_to_internet_on_nsg = {
          test-vnet = {
            exposed_ports = ["80","443"]
            priority = 1000
          }
        }
        ports_to_exposed_to_nuance_on_nsg = {
          test-vnet = {
            exposed_ports = ["80","443"]
            priority = 2000
          }
        }
      },
EOS
}

variable "dns_servers" {
  type        = list(string)
  description = "List of IP address for the DNS servers"
  default     = []
}

variable "all_subnets_service_endpoints" {
  type        = list(string)
  description = <<EOS
    The list of Service endpoints to associate with all subnets in this VNET.
    Use the subnet_settings.service_endpoints field to setup per-subnet service endpoints, if neede.
    Possible values include: Microsoft.AzureActiveDirectory, Microsoft.AzureCosmosDB, Microsoft.EventHub, Microsoft.KeyVault, Microsoft.ServiceBus, Microsoft.Sql and Microsoft.Storage.
  EOS
  default     = []
}

variable "firewall_pips" {
  type        = map(any)
  default     = {}
  description = "A Map of public IP resources"
}

variable "firewall_sku_name" {
  type        = string
  description = "(Optional) SKU name of the Firewall. Possible values are AZFW_Hub and AZFW_VNet. Changing this forces a new resource to be created."
  default     = "AZFW_VNet"
}

variable "firewall_sku_tier" {
  type        = string
  description = "(Optional) SKU tier of the Firewall. Possible values are Premium and Standard. Changing this forces a new resource to be created."
  default     = "Standard"
}

variable "nat_rule_collections" {
  type = map(object({
    priority = number
    action   = string
    rules = map(object({
      source_addresses      = list(string)
      destination_ports     = list(string)
      destination_addresses = list(string)
      translated_address    = string
      translated_port       = string
      protocols             = list(string)
    }))
  }))
  default     = {}
  description = <<EOS
  A map defining different nat rule collections
  Required Keys:
    - key: (Required) Specifies the name of the NAT Rule Collection which must be unique within the Firewall. Changing this forces a new resource to be created.
    - value: object
      - (Required) priority: Specifies the priority of the rule collection. Possible values are between 100 - 65000.
      - (Required) action: Specifies the action the rule will apply to matching traffic. Possible values are Dnat and Snat.
      - rules: map
        - key: name: Specifies the name of the rule.
        - value: object
          - (Required) source_addresses: A list of source IP addresses and/or IP ranges.
          - (Required) destination_addresses: A list of destination IP addresses and/or IP ranges.
          - (Required) destination_ports: A list of destination ports.
          - (Required) translated_address: The address of the service behind the Firewall.
          - (Required) translated_port: The port of the service behind the Firewall.
          - (Required) protocols: A list of protocols. Possible values are Any, ICMP, TCP and UDP. If action is Dnat, protocols can only be TCP and UDP.
  Example:
    nat_rule_collections = {
      gatekeeper = {
        priority = 100
        action   = "Dnat"
        rules = {
          gatekeeper-dev = {
            source_addresses      = ["*"]
            destination_ports     = ["443"]
            destination_addresses = [azurerm_public_ip.firewall_pips["gatekeeper-dev"].ip_address]
            translated_address    = "10.58.160.195"
            translated_port       = "443"
            protocols             = ["TCP"]
          },
        }
      }
    }
EOS
}

variable "network_rule_collections" {
  type = map(object({
    priority = number
    action   = string
    rules = map(object({
      source_addresses      = list(string)
      destination_ports     = list(string)
      destination_addresses = list(string)
      protocols             = list(string)
    }))
  }))
  default     = {}
  description = <<EOS
  A map defining different nat rule collections
  Required Keys:
    - key: (Required) Specifies the name of the NAT Rule Collection which must be unique within the Firewall. Changing this forces a new resource to be created.
    - value: object
      - (Required) priority: Specifies the priority of the rule collection. Possible values are between 100 - 65000.
      - (Required) action: Specifies the action the rule will apply to matching traffic. Possible values are Allow and Deny.
      - rules: map
        - key: name: Specifies the name of the rule.
        - value: object
          - (Required) destination_addresses: A list of destination IP addresses and/or IP ranges.
          - (Required) destination_ports: A list of destination ports.
          - (Required) protocols: A list of protocols. Possible values are Any, ICMP, TCP and UDP. If action is Dnat, protocols can only be TCP and UDP.
          - (Required) source_addresses: A list of source IP addresses and/or IP ranges.
  Example:
    network_rule_collections = {
      cicd-vnet = {
        priority = 100
        action   = "Allow"
        rules = {
          gatekeeper-lambda-vpc = {
            source_addresses      = ["52.7.83.40"]
            destination_ports     = ["443"]
            destination_addresses = ["10.58.128.0/17"]
            protocols             = ["TCP"]
          },
        }
      }
    }
EOS
}

variable "nuance_office_outbound_ips" {
  type        = map(string)
  description = "List of Nuance Outbound IPs"
  default = {
    Aachen        = "46.183.102.26"
    Burlington    = "199.4.160.10"
    Germany       = "5.145.131.136"
    Italy         = "212.31.238.205"
    Mahwah        = "65.51.46.226"
    Montreal      = "192.40.239.178"
    Paris         = "62.23.113.6"
    Pune          = "182.74.39.237"
    Somerville    = "63.116.138.11"
    IsraelDC      = "82.80.207.4"
    IsraelOffice  = "87.71.159.22"
    IsraelOffice2 = "37.142.14.30"
    Seattle       = "74.203.58.130"
    Melbourne     = "208.51.96.2"
    AgouraHills   = "12.232.165.4"
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "(Optional) ID of the log analytics workspace"
  default     = ""
}

variable "logs_eventhub_name" {
  type        = string
  description = "(Optional) Specifies the name of the Event Hub where LOGS Diagnostics Data should be sent. Changing this forces a new resource to be created."
  default     = ""
}

variable "metrics_eventhub_name" {
  type        = string
  description = "(Optional) Specifies the name of the Event Hub where METRICS Diagnostics Data should be sent. Changing this forces a new resource to be created."
  default     = ""
}

variable "eventhub_namespace_authorization_rule_id" {
  type        = string
  description = "(Optional) Specifies the ID of an Event Hub Namespace Authorization Rule used to send Diagnostics Data. Changing this forces a new resource to be created."
  default     = ""
}

variable "diagnostic_setting_storage_account_id" {
  type        = string
  description = "(Optional) Specifies the ID of an storage account used to send Diagnostics Data. Changing this forces a new resource to be created."
  default     = ""
}
variable "log_analytics_destination_type" {
  type        = string
  description = "(Optional) PLACEHOLDER - Sends diagnostic logs to reasource table instead of diagnostic table in LAW - NOT IN USE ON THIS RESOURCE TYPE YET. Has no effect if log_analytics_workspace_id not provided."
  default     = null
}

variable "nsg_diagnostic_log_enabled" {
  type        = bool
  description = "(Optional) Send all nsg log types to diagnostic destination. Only works if one of diagnostic_setting_storage_account_id, metrics_eventhub_name or log_analytics_workspace_id are set."
  default     = false
}

variable "vnet_diagnostic_log_enabled" {
  type        = bool
  description = "(Optional) Send all vnet log types to diagnostic destination. Only works if one of diagnostic_setting_storage_account_id, metrics_eventhub_name or log_analytics_workspace_id are set."
  default     = false
}

variable "fw_log_types_to_disable" {
  type    = list(string)
  default = ["AzureFirewallApplicationRule", "AzureFirewallDnsProxy", "AzureFirewallNetworkRule"]
  validation {
    condition = length([
      for logType in var.fw_log_types_to_disable : logType
      if !can(contains(["AzureFirewallApplicationRule", "AzureFirewallDnsProxy", "AzureFirewallNetworkRule"], logType))
    ]) == 0
    error_message = "Provide a list of either [] or list containing one or more of AzureFirewallApplicationRule, AzureFirewallDnsProxy, AzureFirewallNetworkRule."
  }
  description = <<EOS
  -------------------------------------
  (Optional)
  List of log types the diagnostis settings can send to LAW, can only contain the following. Only works if one of diagnostic_setting_storage_account_id, metrics_eventhub_name or log_analytics_workspace_id are set.
  Defaults to ["AzureFirewallApplicationRule", "AzureFirewallDnsProxy", "AzureFirewallNetworkRule"]
  Can contain: "AzureFirewallApplicationRule", "AzureFirewallDnsProxy", "AzureFirewallNetworkRule"
  -------------------------------------
EOS
}

variable "pip_log_types_to_disable" {
  type    = list(string)
  default = ["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports", "DDoSProtectionNotifications"]
  validation {
    condition = length([
      for logType in var.pip_log_types_to_disable : logType
      if !can(contains(["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports", "DDoSProtectionNotifications"], logType))
    ]) == 0
    error_message = "Provide a list of either [] or list containing one or more of DDoSProtectionNotifications, DDoSMitigationFlowLogs, DDoSMitigationReports, DDoSProtectionNotifications."
  }
  description = <<EOS
  -------------------------------------
  (Optional)
  List of log types the diagnostis settings can send to LAW, can only contain the following. Only works if one of diagnostic_setting_storage_account_id, metrics_eventhub_name or log_analytics_workspace_id are set.
  Defaults to ["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports", "DDoSProtectionNotifications"]
  Can contain: "DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports", "DDoSProtectionNotifications"
  -------------------------------------
EOS
}

variable "vnet_metrics_enabled" {
  type        = bool
  description = "(Optional) Send vnet metrics to diagnostic destination. Only works if one of diagnostic_setting_storage_account_id, metrics_eventhub_name or log_analytics_workspace_id are set."
  default     = false
}

variable "firewall_metrics_enabled" {
  type        = bool
  description = "(Optional) Send Azure firewall metrics to diagnostic destination. Only works if one of diagnostic_setting_storage_account_id, metrics_eventhub_name or log_analytics_workspace_id are set."
  default     = false
}

variable "pip_metrics_enabled" {
  type        = bool
  description = "(Optional) Send Azure public IP metrics to diagnostic destination. Only works if one of diagnostic_setting_storage_account_id, metrics_eventhub_name or log_analytics_workspace_id are set."
  default     = false
}

variable "private_dns_zones" {
  type        = list(string)
  default     = []
  description = <<EOS
    Domain of the private dns zones to create and link to the vnet created in this module.
    Single labeled private DNS zones are not supported. Your private DNS zone must have two or more labels. For example nuance.com has two labels separated by a dot. A private DNS zone can have a maximum 34 labels.
    For example:
      [ "my-dns.com", "my-domain.net" ]
EOS
}

variable "azurerm_lock_enabled" {
  type        = bool
  default     = true
  description = "Flag to enable/disable azurerm resource locks on resources"
}

variable "nsg_flow_enabled" {
  type        = bool
  default     = false
  description = "Enable NSG flow logs for all declared NSGs. This option cannot be managed per individual NSG."
}

variable "nsg_flow_sa_id" {
  type        = string
  default     = null
  description = <<EOS
    The storage account ID to send NSG flow logs.
    WARNING: Must be in the same region as the NSGs!
    Review requirements and limitations at
    https://docs.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-overview#nsg-flow-logging-considerations
EOS
}

variable "nsg_flow_retention" {
  type        = number
  default     = 10
  description = "Number of days to retain NSG flow logs."
}

variable "firewall_public_ip_tags" {
  type        = map(string)
  default     = {}
  description = "Azure resource tags for firewall public ip."
}

variable "firewall_public_ip_availability_zones" {
  type        = list(string)
  description = "Zones for default firewal public IP. Defaults to 1,2,3. Some regions don't support multiple zones; you might have to change this. Changing this forces a new resource to be created."
  default     = ["1", "2", "3"]
}

variable "firewall_tags" {
  type        = map(string)
  default     = {}
  description = "Azure resource tags for Firewall."
}

variable "private_dns_zone_tags" {
  type        = map(string)
  default     = {}
  description = "Azure resource tags for private dns zone."
}

variable "private_dns_zone_virtual_network_link_tags" {
  type        = map(string)
  default     = {}
  description = "Azure resource tags for private dns zone virtual network link."
}

variable "resource_group_tags" {
  type        = map(string)
  default     = {}
  description = "Specify the tags for the resource group specifically in addition to those from var.tags."
}
