variable "is_secondary" {
  type        = bool
  default     = false
  description = "(Optional) Toggle this module to create a secondary failover server and its resources."
}

variable "server_name" {
  type        = string
  description = "(Required) The name of the mssql server."
}

variable "location" {
  type        = string
  description = "(Required) The Azure location of the resources."
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the resources."
}

variable "mssql_version" {
  type        = string
  description = "(Optional) The version for the mssql server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server)."
  default     = "12.0"
}

variable "server_admin_username" {
  type        = string
  description = "(Required) The administrator login name for the mssql server."
}

variable "server_admin_password" {
  type        = string
  description = <<EOS
    (Required) The password associated with the administrator_login user.
    Needs to comply with Azure's Password Policy at https://msdn.microsoft.com/library/ms161959.aspx
      Your password must be at least 8 characters in length.
      Your password must be no more than 128 characters in length.
      Your password must contain characters from three of the following categories – English uppercase letters, English lowercase letters, numbers (0-9), and non-alphanumeric characters (!, $, #, %, etc.).
      Your password cannot contain all or part of the login name. Part of a login name is defined as three or more consecutive alphanumeric characters.
EOS
  validation {
    condition     = length(var.server_admin_password) >= 8
    error_message = "Admin password must be at least 8 characters in length."
  }
  validation {
    condition     = length(var.server_admin_password) <= 128
    error_message = "Admin password must be no more than 128 characters in length."
  }
}

variable "server_connection_policy" {
  type        = string
  description = "(Optional) The connection policy the server will use. Possible values are Default, Proxy, and Redirect. Defaults to Default."
  default     = "Default"
}

variable "enable_public_network_access" {
  type        = bool
  description = "(Optional) Whether public network access is allowed for this server. Defaults to true. Setting to false will require a private endpoint to be created."
  default     = false
}

variable "minimum_tls_version" {
  type        = string
  description = "(Optional) The Minimum TLS Version for all SQL Database and SQL Data Warehouse databases associated with the server. Valid values are: 1.0, 1.1 and 1.2."
  default     = "1.2"
}

variable "azuread_administrator" {
  type = object({
    login_username = string
    object_id      = string
    tenant_id      = optional(string)
  })
  default     = null
  description = <<EOS
    (Optional) The Azure AD Administrator of this SQL Server.
    keys:
      login_username = (Required) The login username of the Azure AD Administrator of this SQL Server.
      object_id      = (Required) The object id of the Azure AD Administrator of this SQL Server.
      tenant_id      = (Optional) The tenant id of the Azure AD Administrator of this SQL Server.
EOS
}

variable "server_tags" {
  type        = map(string)
  description = "Azure resource tags for mssql servers"
  default     = {}
}

variable "db_creation_source_ids" {
  type        = map(string)
  description = <<EOS
    (Optional) The id of the source database to be referred to create the new database.
    The keys should be the name of the databases, and the values should be the id of the databases.
    This should only be used when var.is_secondary is set to true.
EOS
  default     = {}
}

variable "elastic_pools" {
  type = map(object({
    enable_zone_redundant = optional(bool)
    max_size_gb           = optional(number)
    max_capacity_per_db   = number
    min_capacity_per_db   = number
    tags                  = optional(map(string))
    sku = object({
      name     = string
      capacity = number
      tier     = string
      family   = optional(string)
    })
  }))
  default     = {}
  description = <<EOS
  (Optional) Create elastic pools in the mssql server.
  Map keys will be the name of the elastic pools.
  Config keys:
    enable_zone_redundant = (Optional) Whether or not this elastic pool is zone redundant. SKU tier needs to be Premium for DTU based or BusinessCritical for vCore based sku. Defaults to false.
    max_size_gb           = (Optional) The max data size of the elastic pool in gigabytes.
    max_capacity_per_db   = (Required) The maximum capacity any one database can consume. This must match the capacity of one of the sku.
    min_capacity_per_db   = (Required) The minimum capacity all databases are guaranteed. This must match the capacity of one of the sku.
    tags                  = (Optional) Azure resource tags for this elastic pool
    sku = (Required) The SKU of the elastic pool. This defines the total capacity of the pool.
          The available SKUs can be found by this AZ CLI command:
            az sql elastic-pool list-editions -o table -l <azure location>
          For example, the table below shows a few entries from the command above:
          Sku(name)     Edition(tier)     Family    Capacity    Unit    Available
          ------------  ----------------  --------  ----------  ------  -----------
          StandardPool  Standard                    50          DTU     True
          PremiumPool   Premium                     125         DTU     True
          PremiumPool   Premium                     250         DTU     True
          BC_DC         BusinessCritical  DC        2           VCores  True
          BC_Gen5       BusinessCritical  Gen5      4           VCores  True
          GP_Gen5       GeneralPurpose    Gen5      2           VCores  True
          GP_DC         GeneralPurpose    DC        2           VCores  True
      name     = The name of the SKU from the SKU(name) column
      capacity = The capacity of the SKU from the capacity column
      tier     = The tier of the SKU from the Edition(tier) column
      family   = (Optional) The tier of the SKU from the Family column if available
EOS
}

variable "databases" {
  type = map(object({
    auto_pause_delay_in_minutes    = optional(number)
    backup_storage_redundancy_type = optional(string)
    collation                      = optional(string)
    elastic_pool_name              = optional(string)
    enable_geo_backup              = optional(bool)
    enable_read_scale              = optional(bool)
    enable_zone_redundant          = optional(bool)
    max_size_gb                    = optional(number)
    min_capacity                   = optional(number)
    read_replica_count             = optional(number)
    sku_name                       = optional(string)
    tags                           = optional(map(string))
    short_term_retention_days      = optional(number)
    long_term_retention_policy = optional(object({
      weekly_retention  = optional(string)
      monthly_retention = optional(string)
      yearly_retention  = optional(string)
      week_of_year      = optional(number)
    }))
  }))
  default     = {}
  description = <<EOS
  (Optional) Configure databases on the mssql server.
  Each key of the map is the name of the database.
  Confige for each database:
    auto_pause_delay_in_minutes    = (Optional) Time in minutes after which database is automatically paused.
                                                This property is only settable for General Purpose Serverless databases.
                                                Minimum: 60 minutes (1 hour)
                                                Maximum: 10080 minutes (7 days)
                                                Increments: 10 minutes
                                                Disable autopause: -1
                                                See details at https://docs.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview#onboarding-into-serverless-compute-tier
    backup_storage_redundancy_type = (Optional) Specifies the redundancy type of storage account type used to store backups for this database. Changing this forces a new resource to be created.
                                                Possible values are GRS, LRS and ZRS. The default value is GRS.
    collation                      = (Optional) Specifies the collation of the database. Changing this forces a new resource to be created.
    elastic_pool_name              = (Optional) Specifies the name of the elastic pool containing this database.
    enable_geo_backup              = (Optional) A boolean that specifies if the Geo Backup Policy is enabled.
                                                It is only applicable for DataWarehouse SKUs (DW*). This setting is ignored for all other SKUs.
    enable_read_scale              = (Optional) If enabled, connections that have application intent set to readonly in their connection string may be routed to a readonly secondary replica.
                                                This property is only settable for Premium and Business Critical databases.
    enable_zone_redundant          = (Optional) Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones.
                                                This property is only settable for Premium and Business Critical databases.
                                                It is ignored when db is created in an elastic pool because this config would be controlled by the elastic pool.
    max_size_gb                    = (Optional) The max size of the database in gigabytes. It must not be higher than the sku's max hard limit.
                                                It defaults to a much smaller size then the max hard limit.
                                                Only certain numbers are accepted. Every sku has different acceptable numbers. It should be tested on azure portal for validity.
                                                It is ignored when var.is_secondary is set to true because it will follow the same primary db.
    min_capacity                   = (Optional) Minimal capacity that database will always have allocated, if not paused.
                                                This property is only settable for Serverless databases.
    read_replica_count             = (Optional) The number of readonly secondary replicas associated with the database to which readonly application intent connections may be routed.
                                                This property is only settable for Hyperscale edition databases.
    sku_name                       = (Required) Specifies the name of the sku used by the database. Only changing this from tier Hyperscale to another tier will force a new resource to be created.
                                                For example, GP_S_Gen5_2,HS_Gen4_1,BC_Gen5_2, ElasticPool, Basic,S0, P2 ,DW100c, DS100.
                                                To get the complete list of available SKUs in a region, run this Azure CLI command:
                                                   az sql db list-editions -o table -l <azure region>
                                                It should be set to "ElasticPool" when joining an elastic pool.
    tags                           = (Optional) Azure resource tags
    short_term_retention_days       = (Optional)  Configure the retention days of the weekly backup. Value has to be between 7 and 35.
    long_term_retention_policy      = (Optional)  Configure the retention policy to keep the database backups for long term storage.
                                                  See https://docs.microsoft.com/en-us/azure/azure-sql/database/long-term-retention-overview for details
      weekly_retention  = (Optional) The weekly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 520 weeks. e.g. P1Y, P1M, P1W or P7D.
      monthly_retention = (Optional) The monthly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 120 months. e.g. P1Y, P1M, P4W or P30D.
      yearly_retention  = (Optional) The yearly retention policy for an LTR backup in an ISO 8601 format. Valid value is between 1 to 10 years. e.g. P1Y, P12M, P52W or P365D.
      week_of_year      = (Optional) The week of year to take the yearly backup in an ISO 8601 format. Value has to be between 1 and 52.
  usefull links
    https://docs.microsoft.com/en-us/azure/azure-sql/database/resource-limits-dtu-single-databases
    https://docs.microsoft.com/en-us/azure/azure-sql/database/resource-limits-vcore-single-databases
EOS
}

variable "enable_data_encryption" {
  type        = bool
  default     = true
  description = "Toggle to enable sql transparent data encryption."
}

variable "encryption_key_id" {
  type        = string
  default     = null
  description = <<EOS
    The id of the key in Azure Key Vault for sql data encryption.
    If not provided while var.enable_data_encryption is set to true, a service managed key would be used.
EOS
}

variable "auditing" {
  type = object({
    log_analytics = optional(object({
      workspace_id     = string
      destination_type = optional(string)
    }))
    eventhub = optional(object({
      name    = string
      rule_id = string
    }))
    storage_account = optional(object({
      id             = string
      retention_days = optional(number)
    }))
    log_types_to_disable    = optional(list(string))
    metric_types_to_disable = optional(list(string))
  })
  default     = {}
  description = <<EOS
    It configures the auditing of the mssql server. The auditing configs are applied to the server level, which is automatically inherited by all databases.
    To enable auditing, one of the three audit destinations must be provided, log_analytics, eventhub, or storage_account.
    Keys:
      log_analytics = (optional)  Configs for sending audit logs to Log Analytics.
        workspace_id     = (required) The workspace id of the Log Analytics.
        destination_type = (optional) Log Analytic table type. Do not specify a value unless for troubleshooting. Possible values are "Dedicated" and "AzureDiagnostics".
      eventhub = (optional) Configs for sending audit logs to Eventhub.
        name    = (required)  The name of the Event Hub.
        rule_id = (required)  The ID of an Event Hub Namespace Authorization Rule.
      storage_account = (optional)  Configs for sending audit logs to a storage account.
                        For it to work properly, the storage must allow public network access.
        id             = (required) The id of the storage account.
        retention_days = (optional) The retention period in days of the logs. Set to 0 to retain forever, or set to a number between 1 and 365.
      log_types_to_disable    = (optional)  A list of audit log categories to NOT send. The list can be obtained from output "audit_categories"
      metric_types_to_disable = (optional)  A list of audit metric categories to NOT send. The list can be obtained from output "audit_categories"
EOS
}

variable "allowed_vnets" {
  type        = list(string)
  description = "A list of vnet id allowed to connect to server."
  default     = []
}

variable "firewall_rules" {
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default     = {}
  description = <<EOS
    Firewall rule for allowed Ip ranges to access the msql server
    Map keys are the name of the rules.
    Required keys:
      start_ip      = the IP at the beginning of the allowed IP range
      end_ip=string = the IP at the end of the allowed IP range
    Example:
    {
      test = {
        start_ip  = "1.1.1.1"
        end_ip    = "2.2.2.2"
      },
      microsoft = {
        start_ip  = "3.3.3.3"
        end_ip    = "4.4.4.4"
      }
    }
EOS
}