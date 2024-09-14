variable "location" {
  type        = string
  description = "The region to place the resources"
}

variable "rg_name" {
  type        = string
  description = "The resource group name to place the scale sets in"
}

variable "scale_sets" {
  description = "The scale sets list of object variable"
  type = list(object({
    name                                              = string
    computer_name_prefix                              = optional(string)
    admin_username                                    = string
    admin_password                                    = string
    edge_zone                                         = optional(string)
    instances                                         = optional(number)
    sku                                               = optional(string)
    custom_data                                       = optional(string)
    disable_password_authentication                   = optional(bool)
    user_date                                         = optional(string)
    do_not_run_extensions_on_overprovisioned_machines = optional(bool)
    extensions_time_budget                            = optional(string)
    priority                                          = optional(string)
    max_bid_price                                     = optional(number)
    identity_type                                     = optional(string)
    identity_ids                                      = optional(list(string))
    eviction_policy                                   = optional(string)
    health_probe_id                                   = optional(string)
    timezone                                          = optional(string)
    overprovision                                     = optional(bool)
    create_asg                                        = optional(bool, false)
    asg_name                                          = optional(string)
    enable_automatic_updates                          = optional(bool)
    extension_operations_enabled                      = optional(bool)
    platform_fault_domain_count                       = optional(number)
    upgrade_mode                                      = optional(string)
    proximity_placement_group_id                      = optional(string)
    secure_boot_enabled                               = optional(bool)
    use_custom_image                                  = optional(bool, false)
    host_group_id                                     = optional(string)
    license_type                                      = optional(string)
    use_custom_image_with_plan                        = optional(bool, false)
    use_simple_image                                  = optional(bool, true)
    use_simple_image_with_plan                        = optional(bool, false)
    vm_os_id                                          = optional(string, "")
    vm_os_offer                                       = optional(string)
    vm_os_publisher                                   = optional(string)
    vm_os_simple                                      = optional(string)
    vm_os_sku                                         = optional(string)
    vm_os_version                                     = optional(string)
    spot_restore = optional(object({
      enabled = optional(bool)
      timeout = optional(number)
    }))
    scale_in = optional(object({
      rule                   = optional(string)
      force_deletion_enabled = optional(string)
    }))
    gallery_applications = optional(list(object({
      version_id             = string
      configuration_blob_uri = optional(string)
      order                  = optional(number)
      tag                    = optional(string)
    })))
    plan = optional(object({
      name      = optional(string)
      product   = optional(string)
      publisher = optional(string)
    }))
    source_image_reference = optional(object({
      publisher = optional(string)
      offer     = optional(string)
      sku       = optional(string)
      version   = optional(string)
    }))
    single_placement_group     = optional(bool)
    custom_source_image_id     = optional(string)
    vtpm_enabled               = optional(bool)
    zone_balance               = optional(bool)
    zones                      = optional(list(string))
    encryption_at_host_enabled = optional(bool)
    provision_vm_agent         = optional(bool)
    additional_unattend_content = optional(list(object({
      content = string
      setting = string
    })))
    winrm_listener = optional(list(object({
      protocol        = string
      certificate_url = optional(string)
    })))
    rolling_upgrade_policy = optional(object({
      max_batch_instance_percent              = optional(number)
      max_unhealthy_instance_percent          = optional(number)
      max_unhealthy_upgraded_instance_percent = optional(number)
      pause_time_between_batches              = optional(string)
    }))
    termination_notification = optional(object({
      enabled = optional(bool)
      timeout = optional(string)
    }))
    secrets = optional(list(object({
      key_vault_id = string
      certificates = list(object({
        store = string
        url   = string
      }))
    })))
    os_disk = object({
      caching                          = optional(string, "ReadWrite")
      storage_account_type             = optional(string)
      disk_size_gb                     = optional(number)
      disk_encryption_set_id           = optional(string)
      secure_vm_disk_encryption_set_id = optional(string)
      security_encryption_type         = optional(string)
      write_accelerator_enabled        = optional(bool)
      diff_disk_settings = optional(object({
        option    = string
        placement = optional(string)
      }))
    })
    data_disk = optional(list(object({
      lun                       = number
      caching                   = optional(string)
      storage_account_type      = optional(string)
      disk_size_gb              = optional(number)
      write_accelerator_enabled = optional(bool)
      disk_encryption_set_id    = optional(string)
    })))
    extension = optional(list(object({
      name                       = string
      publisher                  = string
      type                       = string
      type_handler_version       = string
      auto_upgrade_minor_version = optional(bool)
      automatic_upgrade_enabled  = optional(bool)
      force_update_tag           = optional(string)
      provision_after_extensions = optional(list(string))
      settings                   = optional(string)
      protected_settings         = optional(string)
      protected_settings_from_key_vault = optional(object({
        secret_url      = optional(string)
        source_vault_id = optional(string)
      }))
    })))
    boot_diagnostics_storage_account_uri = optional(string, null)
    additional_capabilities = optional(object({
      ultra_ssd_enabled = optional(bool)
    }))
    automatic_os_upgrade_policy = optional(object({
      disable_automatic_rollback  = optional(bool)
      enable_automatic_os_upgrade = optional(bool)
    }))
    automatic_instance_repair = optional(object({
      enabled      = optional(bool)
      grace_period = optional(string)
    }))
    network_interface = optional(list(object({
      name                          = optional(string)
      primary                       = optional(bool)
      network_security_group_id     = optional(string)
      enable_accelerated_networking = optional(bool)
      enable_ip_forwarding          = optional(bool)
      dns_servers                   = optional(list(string))
      ip_configuration = optional(list(object({
        name                                         = optional(string)
        primary                                      = optional(bool)
        application_gateway_backend_address_pool_ids = optional(list(string))
        application_security_group_ids               = optional(list(string))
        load_balancer_backend_address_pool_ids       = optional(list(string))
        load_balancer_inbound_nat_rules_ids          = optional(list(string))
        version                                      = optional(string)
        subnet_id                                    = optional(string)
        public_ip_address = optional(object({
          name                    = optional(string)
          domain_name_label       = optional(string)
          idle_timeout_in_minutes = optional(number)
          public_ip_prefix_id     = optional(string)
          ip_tag = optional(list(object({
            type = optional(string)
            tag  = optional(string)
          })))
        }))
      })))
    })))
  }))
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to the resource"
}
