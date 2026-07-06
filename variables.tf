variable "location" {
  description = "Azure region for the scale sets."
  type        = string
}

variable "resource_group_id" {
  description = "Resource id of the resource group the scale sets are created in. The resource group name and subscription are parsed from this id."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.resource_group_id).resource_type, "") == "resourceGroups"
    error_message = "resource_group_id must be a resource group resource id."
  }
}

variable "scale_sets" {
  description = <<-EOT
    Uniform-orchestration Windows virtual machine scale sets keyed by name (vmssldouksprd001, the
    no-dash convention). Highlights:
      sku / instances          The size and instance count.
      zones                    Zone-redundant ["1", "2", "3"] by default; set [] for regions
                               without zones.
      Authentication           admin_username plus admin_password (required by the resource);
                               computer_name_prefix must be 9 characters or fewer (validated;
                               falls back to the scale set name).
      Trusted Launch           secure_boot_enabled and vtpm_enabled default true; every catalog
                               image is Gen2 and Trusted Launch capable.
      source_image_simple      A catalog key (see image_catalog_keys output); or
                               source_image_reference / source_image_id. Catalog plans (Rocky)
                               flow through; accept_marketplace_agreement = true accepts the terms
                               on first use.
      network_interfaces       Map keyed by NIC name; each carries ip_configurations keyed by
                               name (subnet_id plus optional load balancer pools and inbound NAT
                               rules, application gateway pools, ASGs, and an inline public ip per
                               instance). Single NIC and single ip configuration are primary
                               automatically.
      upgrade_mode             Manual (provider default), Automatic, or Rolling;
                               rolling_upgrade_policy requires Rolling, and automatic OS upgrades
                               (automatic_os_upgrade_policy) need a health probe or extension.
      priority                 Regular (default) or Spot (with eviction_policy, max_bid_price,
                               and spot_restore).
  EOT
  type = map(object({
    sku       = string
    instances = optional(number, 1)

    zones                       = optional(set(string), ["1", "2", "3"])
    zone_balance                = optional(bool)
    platform_fault_domain_count = optional(number)
    single_placement_group      = optional(bool)
    overprovision               = optional(bool)
    tags                        = optional(map(string))

    admin_username       = string
    admin_password       = string
    computer_name_prefix = optional(string)

    enable_automatic_updates = optional(bool, true)
    timezone                 = optional(string)
    license_type             = optional(string)

    additional_unattend_content = optional(list(object({
      content = string
      setting = string
    })), [])

    winrm_listeners = optional(list(object({
      protocol        = string
      certificate_url = optional(string)
    })), [])

    source_image_simple = optional(string)
    source_image_id     = optional(string)
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = optional(string, "latest")
    }))
    plan = optional(object({
      name      = string
      product   = string
      publisher = string
    }))
    accept_marketplace_agreement = optional(bool, false)

    os_disk = optional(object({
      caching                          = optional(string, "ReadWrite")
      storage_account_type             = optional(string, "StandardSSD_LRS")
      disk_size_gb                     = optional(number)
      disk_encryption_set_id           = optional(string)
      secure_vm_disk_encryption_set_id = optional(string)
      security_encryption_type         = optional(string)
      write_accelerator_enabled        = optional(bool, false)
      diff_disk_settings = optional(object({
        option    = string
        placement = optional(string)
      }))
    }), {})

    data_disks = optional(list(object({
      caching                        = optional(string, "ReadWrite")
      storage_account_type           = optional(string, "StandardSSD_LRS")
      disk_size_gb                   = number
      lun                            = optional(number)
      name                           = optional(string)
      create_option                  = optional(string)
      disk_encryption_set_id         = optional(string)
      ultra_ssd_disk_iops_read_write = optional(number)
      ultra_ssd_disk_mbps_read_write = optional(number)
      write_accelerator_enabled      = optional(bool)
    })), [])

    network_interfaces = map(object({
      primary                        = optional(bool)
      accelerated_networking_enabled = optional(bool, false)
      ip_forwarding_enabled          = optional(bool, false)
      dns_servers                    = optional(list(string))
      network_security_group_id      = optional(string)
      auxiliary_mode                 = optional(string)
      auxiliary_sku                  = optional(string)
      ip_configurations = map(object({
        subnet_id                                    = string
        primary                                      = optional(bool)
        version                                      = optional(string)
        load_balancer_backend_address_pool_ids       = optional(set(string))
        load_balancer_inbound_nat_rules_ids          = optional(set(string))
        application_gateway_backend_address_pool_ids = optional(set(string))
        application_security_group_ids               = optional(set(string))
        public_ip_address = optional(object({
          name                    = string
          domain_name_label       = optional(string)
          idle_timeout_in_minutes = optional(number)
          public_ip_prefix_id     = optional(string)
          version                 = optional(string)
          ip_tags = optional(list(object({
            tag  = string
            type = string
          })), [])
        }))
      }))
    }))

    extensions = optional(map(object({
      publisher                  = string
      type                       = string
      type_handler_version       = string
      auto_upgrade_minor_version = optional(bool, true)
      automatic_upgrade_enabled  = optional(bool)
      force_update_tag           = optional(string)
      settings                   = optional(string)
      protected_settings         = optional(string)
      provision_after_extensions = optional(list(string))
      protected_settings_from_key_vault = optional(object({
        secret_url      = string
        source_vault_id = string
      }))
    })), {})

    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(set(string))
    }), {})

    boot_diagnostics = optional(object({
      enabled             = optional(bool, true)
      storage_account_uri = optional(string)
    }), {})

    secure_boot_enabled        = optional(bool, true)
    vtpm_enabled               = optional(bool, true)
    encryption_at_host_enabled = optional(bool)

    priority        = optional(string, "Regular")
    eviction_policy = optional(string)
    max_bid_price   = optional(number)
    spot_restore = optional(object({
      enabled = optional(bool, true)
      timeout = optional(string)
    }))

    upgrade_mode    = optional(string)
    health_probe_id = optional(string)
    rolling_upgrade_policy = optional(object({
      max_batch_instance_percent              = optional(number, 20)
      max_unhealthy_instance_percent          = optional(number, 20)
      max_unhealthy_upgraded_instance_percent = optional(number, 20)
      pause_time_between_batches              = optional(string, "PT30S")
      cross_zone_upgrades_enabled             = optional(bool)
      maximum_surge_instances_enabled         = optional(bool)
      prioritize_unhealthy_instances_enabled  = optional(bool)
    }))
    automatic_os_upgrade_policy = optional(object({
      disable_automatic_rollback  = optional(bool, false)
      enable_automatic_os_upgrade = optional(bool, true)
    }))
    automatic_instance_repair = optional(object({
      enabled      = bool
      grace_period = optional(string)
      action       = optional(string)
    }))

    scale_in = optional(object({
      rule                   = optional(string)
      force_deletion_enabled = optional(bool)
    }))

    gallery_applications = optional(list(object({
      version_id             = string
      configuration_blob_uri = optional(string)
      order                  = optional(number)
      tag                    = optional(string)
    })), [])

    secrets = optional(list(object({
      key_vault_id = string
      certificates = list(object({
        store = string
        url   = string
      }))
    })), [])

    termination_notification = optional(object({
      enabled = bool
      timeout = optional(string)
    }))

    custom_data                                       = optional(string)
    user_data                                         = optional(string)
    ultra_ssd_enabled                                 = optional(bool)
    capacity_reservation_group_id                     = optional(string)
    proximity_placement_group_id                      = optional(string)
    host_group_id                                     = optional(string)
    edge_zone                                         = optional(string)
    provision_vm_agent                                = optional(bool, true)
    do_not_run_extensions_on_overprovisioned_machines = optional(bool)
    extension_operations_enabled                      = optional(bool)
    extensions_time_budget                            = optional(string)
    resilient_vm_creation_enabled                     = optional(bool)
    resilient_vm_deletion_enabled                     = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for s in values(var.scale_sets) :
      length([for v in [s.source_image_simple, s.source_image_id, s.source_image_reference] : v if v != null]) == 1
    ])
    error_message = "every scale set sets exactly one image source: source_image_simple, source_image_reference, or source_image_id."
  }

  validation {
    condition = alltrue([
      for k, s in var.scale_sets :
      length(coalesce(s.computer_name_prefix, k)) <= 9
    ])
    error_message = "Windows computer_name_prefix (or the scale set name it falls back to) must be 9 characters or fewer."
  }

  validation {
    # try() guards the null side: 1.9 evaluates both || operands.
    condition = alltrue([
      for s in values(var.scale_sets) :
      !try(s.automatic_os_upgrade_policy.enable_automatic_os_upgrade, false) || !s.enable_automatic_updates
    ])
    error_message = "Azure rejects enable_automatic_updates = true together with automatic OS upgrades (enableAutomaticUpdates cannot be true when enableAutomaticOSUpgrade is true): set enable_automatic_updates = false on scale sets with an automatic_os_upgrade_policy."
  }

  validation {
    condition = alltrue([
      for s in values(var.scale_sets) :
      s.priority == "Spot" || (s.eviction_policy == null && s.max_bid_price == null && s.spot_restore == null)
    ])
    error_message = "eviction_policy, max_bid_price, and spot_restore only apply to Spot scale sets (priority = \"Spot\")."
  }

  validation {
    condition     = alltrue([for s in values(var.scale_sets) : s.rolling_upgrade_policy == null || s.upgrade_mode == "Rolling"])
    error_message = "rolling_upgrade_policy requires upgrade_mode = \"Rolling\"."
  }

  validation {
    condition = alltrue([
      for s in values(var.scale_sets) :
      s.automatic_os_upgrade_policy == null || s.health_probe_id != null || length([for e in values(s.extensions) : e if e.type == "ApplicationHealthWindows"]) > 0
    ])
    error_message = "automatic_os_upgrade_policy needs a health signal: a health_probe_id or an ApplicationHealthWindows extension."
  }

  validation {
    condition     = alltrue([for s in values(var.scale_sets) : length(s.network_interfaces) > 0])
    error_message = "every scale set needs at least one network interface."
  }

  validation {
    condition = alltrue([
      for s in values(var.scale_sets) :
      length(s.network_interfaces) == 1 || length([for n in values(s.network_interfaces) : n if coalesce(n.primary, false)]) == 1
    ])
    error_message = "with more than one network interface, exactly one must set primary = true (a single interface is primary automatically)."
  }

  validation {
    condition = alltrue(flatten([
      for s in values(var.scale_sets) : [
        for n in values(s.network_interfaces) :
        length(n.ip_configurations) == 1 || length([for c in values(n.ip_configurations) : c if coalesce(c.primary, false)]) == 1
      ]
    ]))
    error_message = "with more than one ip configuration on an interface, exactly one must set primary = true (a single configuration is primary automatically)."
  }

  validation {
    condition     = alltrue([for s in values(var.scale_sets) : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], s.identity.type)])
    error_message = "identity.type must be SystemAssigned, UserAssigned, or \"SystemAssigned, UserAssigned\"."
  }
}

variable "tags" {
  description = "Tags applied to the scale sets (merged with per-scale-set tags)."
  type        = map(string)
  default     = {}
}
