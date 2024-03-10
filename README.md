```hcl
resource "azurerm_windows_virtual_machine_scale_set" "windows_vm_scale_set" {
  for_each            = { for vm in var.scale_sets : vm.name => vm }
  name                = each.value.name
  resource_group_name = var.rg_name
  location            = var.location
  tags                = var.tags
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password

  computer_name_prefix                              = try(each.value.computer_name_prefix, null)
  edge_zone                                         = try(each.value.edge_zone, null)
  instances                                         = try(each.value.instances, null)
  sku                                               = try(each.value.sku, null)
  custom_data                                       = try(each.value.custom_data, null)
  do_not_run_extensions_on_overprovisioned_machines = try(each.value.do_not_run_extensions_on_overprovisioned_machines, null)
  extensions_time_budget                            = try(each.value.do_not_run_extensions_on_overprovisioned_machines, null)
  priority                                          = try(each.value.priority, null)
  max_bid_price                                     = try(each.value.max_bid_price, null)
  eviction_policy                                   = try(each.value.eviction_policy, null)
  timezone                                          = each.value.timezone
  health_probe_id                                   = try(each.value.health_probe_id, null)
  overprovision                                     = try(each.value.overprovision, true)
  platform_fault_domain_count                       = try(each.value.platform_fault_domain_count, null)
  upgrade_mode                                      = try(each.value.upgrade_mode, null)
  proximity_placement_group_id                      = try(each.value.proximity_placement_group_id, null)
  scale_in_policy                                   = try(each.value.scale_in_policy, null)
  secure_boot_enabled                               = try(each.value.secure_boot_enabled, null)
  user_data                                         = each.value.user_date
  single_placement_group                            = try(each.value.single_placement_group, null)
  source_image_id                                   = try(each.value.use_custom_image, null) == true ? each.value.custom_source_image_id : null
  vtpm_enabled                                      = try(each.value.vtpm_enabled, null)
  zone_balance                                      = try(each.value.zone_balance, null)
  zones                                             = tolist(try(each.value.zones, null))
  enable_automatic_updates                          = each.value.enable_automatic_updates
  extension_operations_enabled                      = each.value.extension_operations_enabled
  host_group_id                                     = each.value.host_group_id
  license_type                                      = each.value.license_type

  #checkov:skip=CKV_AZURE_151:Ensure Encryption at host is enabled
  encryption_at_host_enabled = try(each.value.encryption_at_host_enabled, null)

  #checkov:skip=CKV_AZURE_50:Ensure Virtual Machine extensions are not installed
  provision_vm_agent = try(each.value.provision_vm_agent, null)

  dynamic "spot_restore" {
    for_each = each.value.spot_restore != null ? [each.value.spot_restore] : []
    content {

    }
  }

  dynamic "scale_in" {
    for_each = each.value.scale_in != null ? [each.value.scale_in] : []
    content {

      rule                   = scale_in.value.rule
      force_deletion_enabled = scale_in.value.force_deletion_enabled

    }
  }


  dynamic "gallery_application" {
    for_each = each.value.gallery_applications != null ? each.value.gallery_applications : []
    content {

      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = each.value.rolling_upgrade_policy != null ? [each.value.rolling_upgrade_policy] : []
    content {
      max_batch_instance_percent              = rolling_upgrade_policy.value.max_batch_instance_percent
      max_unhealthy_instance_percent          = rolling_upgrade_policy.value.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = rolling_upgrade_policy.value.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = rolling_upgrade_policy.value.pause_time_between_batches
    }
  }

  # To be removed in version 4 of the provider
  dynamic "termination_notification" {
    for_each = each.value.termination_notification != null ? [each.value.termination_notification] : []
    content {
      enabled = termination_notification.value.enabled
      timeout = termination_notification.value.timeout
    }
  }

  dynamic "additional_unattend_content" {
    for_each = each.value.additional_unattend_content != null ? each.value.additional_unattend_content : []
    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets != null ? each.value.secrets : []
    content {
      key_vault_id = secret.value.key_vault_id

      dynamic "certificate" {
        for_each = secret.value.certificates
        content {
          store = certificate.value.store
          url   = certificate.value.url
        }
      }
    }
  }


  os_disk {
    caching                   = try(each.value.os_disk.caching, null)
    storage_account_type      = try(each.value.os_disk.storage_account_type, null)
    disk_size_gb              = try(each.value.os_disk.disk_size_gb, null)
    disk_encryption_set_id    = try(each.value.os_disk.disk_encryption_set_id, null)
    write_accelerator_enabled = try(each.value.os_disk.write_accelerator_enabled, false)

    dynamic "diff_disk_settings" {
      for_each = each.value.os_disk.diff_disk_settings != null ? [each.value.os_disk.diff_disk_settings] : []
      content {
        option    = diff_disk_settings.value.option
        placement = diff_disk_settings.value.placement
      }
    }
  }

  dynamic "data_disk" {
    for_each = each.value.data_disk != null ? toset(each.value.data_disk) : []
    content {
      lun                       = data_disk.value.lun
      caching                   = data_disk.value.caching
      storage_account_type      = data_disk.value.storage_account_type
      disk_size_gb              = data_disk.value.disk_size_gb
      write_accelerator_enabled = data_disk.value.write_accelerator_enabled
      disk_encryption_set_id    = data_disk.value.disk_encryption_set_id
    }
  }

  dynamic "extension" {
    for_each = each.value.extension != null ? toset(each.value.extension) : []
    content {
      name                       = extension.value.name
      publisher                  = extension.value.publisher
      type                       = extension.value.type
      type_handler_version       = extension.value.type_handler_version
      auto_upgrade_minor_version = extension.value.auto_upgrade_minor_version
      automatic_upgrade_enabled  = extension.value.automatic_upgrade_enabled
      force_update_tag           = extension.value.force_update_tag
      provision_after_extensions = tolist(extension.value.provision_after_extensions)
      settings                   = extension.value.settings
      protected_settings         = extension.value.protected_settings

      dynamic "protected_settings_from_key_vault" {
        for_each = extension.value.protected_settings_from_key_vault != null ? [extension.valueprotected_settings_from_key_vault] : []
        content {

          secret_url      = ""
          source_vault_id = ""
        }
      }

    }
  }

  dynamic "boot_diagnostics" {
    for_each = each.value.boot_diagnostics_storage_account_uri != null ? [
      each.value.boot_diagnostics_storage_account_uri
    ] : [null]
    content {
      storage_account_uri = boot_diagnostics.value
    }
  }

  dynamic "additional_capabilities" {
    for_each = each.value.additional_capabilities != null && each.value.additional_capabilities != {} ? [
      each.value.additional_capabilities
    ] : []
    content {
      ultra_ssd_enabled = additional_capabilities.value.ultra_ssd_enabled
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = each.value.automatic_os_upgrade_policy != null && each.value.automatic_os_upgrade_policy != {} ? [
      each.value.automatic_os_upgrade_policy
    ] : []
    content {
      disable_automatic_rollback  = automatic_os_upgrade_policy.value.disable_automatic_rollback
      enable_automatic_os_upgrade = automatic_os_upgrade_policy.value.enable_automatic_os_upgrade
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = each.value.automatic_instance_repair != null && each.value.automatic_instance_repair != {} ? [
      each.value.automatic_instance_repair
    ] : []
    content {
      enabled      = automatic_instance_repair.value.enabled
      grace_period = automatic_instance_repair.value.grace_period
    }
  }


  dynamic "network_interface" {
    for_each = each.value.network_interface != null && each.value.network_interface != {} ? toset(each.value.network_interface) : []
    content {
      name                          = network_interface.value.name
      primary                       = network_interface.value.primary
      network_security_group_id     = network_interface.value.network_security_group_id
      enable_accelerated_networking = network_interface.value.enable_accelerated_networking
      enable_ip_forwarding          = network_interface.value.enable_ip_forwarding
      dns_servers                   = tolist(network_interface.value.dns_servers)

      dynamic "ip_configuration" {
        for_each = network_interface.value.ip_configuration != null && network_interface.value.ip_configuration != {} ? toset(network_interface.value.ip_configuration) : []
        content {
          name                                         = ip_configuration.value.name
          primary                                      = ip_configuration.value.primary
          application_gateway_backend_address_pool_ids = ip_configuration.value.application_gateway_backend_address_pool_ids
          application_security_group_ids = each.value.create_asg ? (
            ip_configuration.value.application_security_group_ids != null ?
            distinct(concat(ip_configuration.value.application_security_group_ids, [
              azurerm_application_security_group.asg[each.key].id
            ])) :
            [azurerm_application_security_group.asg[each.key].id]
          ) : []
          load_balancer_backend_address_pool_ids = ip_configuration.value.load_balancer_backend_address_pool_ids
          load_balancer_inbound_nat_rules_ids    = ip_configuration.value.load_balancer_inbound_nat_rules_ids
          version                                = ip_configuration.value.version
          subnet_id                              = ip_configuration.value.subnet_id

          dynamic "public_ip_address" {
            for_each = ip_configuration.value.public_ip_address != null && ip_configuration.value.public_ip_address != {} ? [
              ip_configuration.value.public_ip_address
            ] : []
            content {
              name                    = public_ip_address.value.name
              domain_name_label       = public_ip_address.value.domain_name_label
              idle_timeout_in_minutes = public_ip_address.value.idle_timeout_in_minutes
              public_ip_prefix_id     = public_ip_address.value.public_ip_prefix_id

              dynamic "ip_tag" {
                for_each = public_ip_address.value.ip_tag != null && public_ip_address.value.ip_tag != {} ? [
                  public_ip_address.value.ip_tag
                ] : []
                content {
                  type = ip_tag.value.type
                  tag  = ip_tag.value.tag
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "source_image_reference" {
    for_each = try(each.value.use_simple_image, null) == true && try(each.value.use_simple_image_with_plan, null) == false && try(each.value.use_custom_image, null) == false ? [
      1
    ] : []
    content {
      publisher = coalesce(each.value.vm_os_publisher, module.os_calculator[each.value.name].calculated_value_os_publisher)
      offer     = coalesce(each.value.vm_os_offer, module.os_calculator[each.value.name].calculated_value_os_offer)
      sku       = coalesce(each.value.vm_os_sku, module.os_calculator[each.value.name].calculated_value_os_sku)
      version   = coalesce(each.value.vm_os_version, "latest")
    }
  }


  # Use custom image reference
  dynamic "source_image_reference" {
    for_each = try(each.value.use_simple_image, null) == false && try(each.value.use_simple_image_with_plan, null) == false && try(length(each.value.source_image_reference), 0) > 0 && try(length(each.value.plan), 0) == 0 && try(each.value.use_custom_image, null) == false ? [
      1
    ] : []

    content {
      publisher = lookup(each.value.source_image_reference, "publisher", null)
      offer     = lookup(each.value.source_image_reference, "offer", null)
      sku       = lookup(each.value.source_image_reference, "sku", null)
      version   = lookup(each.value.source_image_reference, "version", null)
    }
  }

  dynamic "source_image_reference" {
    for_each = try(each.value.use_simple_image, null) == true && try(each.value.use_simple_image_with_plan, null) == true && try(each.value.use_custom_image, null) == false ? [
      1
    ] : []

    content {
      publisher = coalesce(each.value.vm_os_publisher, module.os_calculator_with_plan[each.value.name].calculated_value_os_publisher)
      offer     = coalesce(each.value.vm_os_offer, module.os_calculator_with_plan[each.value.name].calculated_value_os_offer)
      sku       = coalesce(each.value.vm_os_sku, module.os_calculator_with_plan[each.value.name].calculated_value_os_sku)
      version   = coalesce(each.value.vm_os_version, "latest")
    }
  }


  dynamic "plan" {
    for_each = try(each.value.use_simple_image, null) == false && try(each.value.use_simple_image_with_plan, null) == false && try(length(each.value.plan), 0) > 0 && try(each.value.use_custom_image, null) == false ? [
      1
    ] : []

    content {
      name      = coalesce(each.value.vm_os_sku, module.os_calculator_with_plan[each.value.name].calculated_value_os_sku)
      product   = coalesce(each.value.vm_os_offer, module.os_calculator_with_plan[each.value.name].calculated_value_os_offer)
      publisher = coalesce(each.value.vm_os_publisher, module.os_calculator_with_plan[each.value.name].calculated_value_os_publisher)
    }
  }


  dynamic "plan" {
    for_each = try(each.value.use_simple_image, null) == false && try(each.value.use_simple_image_with_plan, null) == false && try(length(each.value.plan), 0) > 0 && try(each.value.use_custom_image, null) == false ? [
      1
    ] : []

    content {
      name      = lookup(each.value.plan, "name", null)
      product   = lookup(each.value.plan, "product", null)
      publisher = lookup(each.value.plan, "publisher", null)
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [each.value.identity_type] : []
    content {
      type = each.value.identity_type
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned, UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = try(each.value.identity_ids, [])
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = length(try(each.value.identity_ids, [])) > 0 ? each.value.identity_ids : []
    }
  }

  dynamic "winrm_listener" {
    for_each = each.value.winrm_listener != null ? each.value.winrm_listener : []
    content {
      protocol        = winrm_listener.value.protocol
      certificate_url = winrm_listener.value.certificate_url
    }
  }
}

module "os_calculator" {
  source       = "libre-devops/windows-os-sku-calculator/azurerm"
  for_each     = { for vm in var.scale_sets : vm.name => vm if try(vm.use_simple_image, null) == true }
  vm_os_simple = each.value.vm_os_simple
}

module "os_calculator_with_plan" {
  source       = "libre-devops/windows-os-sku-with-plan-calculator/azurerm"
  for_each     = { for vm in var.scale_sets : vm.name => vm if try(vm.use_simple_image_with_plan, null) == true }
  vm_os_simple = each.value.vm_os_simple
}

resource "azurerm_marketplace_agreement" "plan_acceptance_simple" {
  for_each = {
    for vm in var.scale_sets : vm.name => vm
    if try(vm.use_simple_image_with_plan, null) == true && try(vm.accept_plan, null) == true && try(vm.use_custom_image, null) == false
  }

  publisher = coalesce(each.value.vm_os_publisher, module.os_calculator_with_plan[each.key].calculated_value_os_publisher)
  offer     = coalesce(each.value.vm_os_offer, module.os_calculator_with_plan[each.key].calculated_value_os_offer)
  plan      = coalesce(each.value.vm_os_sku, module.os_calculator_with_plan[each.key].calculated_value_os_sku)
}

resource "azurerm_marketplace_agreement" "plan_acceptance_custom" {
  for_each = {
    for vm in var.scale_sets : vm.name => vm
    if try(vm.use_custom_image_with_plan, null) == true && try(vm.accept_plan, null) == true && try(vm.use_custom_image, null) == true
  }

  publisher = lookup(each.value.plan, "publisher", null)
  offer     = lookup(each.value.plan, "product", null)
  plan      = lookup(each.value.plan, "name", null)
}

resource "azurerm_application_security_group" "asg" {
  for_each = { for vm in var.scale_sets : vm.name => vm if vm.create_asg == true }

  name                = each.value.asg_name != null ? each.value.asg_name : "asg-${each.value.name}"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_os_calculator"></a> [os\_calculator](#module\_os\_calculator) | libre-devops/windows-os-sku-calculator/azurerm | n/a |
| <a name="module_os_calculator_with_plan"></a> [os\_calculator\_with\_plan](#module\_os\_calculator\_with\_plan) | libre-devops/windows-os-sku-with-plan-calculator/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_application_security_group.asg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_security_group) | resource |
| [azurerm_marketplace_agreement.plan_acceptance_custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
| [azurerm_marketplace_agreement.plan_acceptance_simple](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
| [azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine_scale_set) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | The region to place the resources | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The resource group name to place the scale sets in | `string` | n/a | yes |
| <a name="input_scale_sets"></a> [scale\_sets](#input\_scale\_sets) | The scale sets list of object variable | <pre>list(object({<br>    name                                              = string<br>    computer_name_prefix                              = optional(string)<br>    admin_username                                    = string<br>    admin_password                                    = string<br>    edge_zone                                         = optional(string)<br>    instances                                         = optional(number)<br>    sku                                               = optional(string)<br>    custom_data                                       = optional(string)<br>    disable_password_authentication                   = optional(bool)<br>    user_date                                         = optional(string)<br>    do_not_run_extensions_on_overprovisioned_machines = optional(bool)<br>    extensions_time_budget                            = optional(string)<br>    priority                                          = optional(string)<br>    max_bid_price                                     = optional(number)<br>    identity_type                                     = optional(string)<br>    identity_ids                                      = optional(list(string))<br>    eviction_policy                                   = optional(string)<br>    health_probe_id                                   = optional(string)<br>    timezone                                          = optional(string)<br>    overprovision                                     = optional(bool)<br>    create_asg                                        = optional(bool, false)<br>    asg_name                                          = optional(string)<br>    enable_automatic_updates                          = optional(bool)<br>    extension_operations_enabled                      = optional(bool)<br>    platform_fault_domain_count                       = optional(number)<br>    upgrade_mode                                      = optional(string)<br>    proximity_placement_group_id                      = optional(string)<br>    scale_in_policy                                   = optional(string)<br>    secure_boot_enabled                               = optional(bool)<br>    use_custom_image                                  = optional(bool, false)<br>    host_group_id                                     = optional(string)<br>    license_type                                      = optional(string)<br>    use_custom_image_with_plan                        = optional(bool, false)<br>    use_simple_image                                  = optional(bool, true)<br>    use_simple_image_with_plan                        = optional(bool, false)<br>    vm_os_id                                          = optional(string, "")<br>    vm_os_offer                                       = optional(string)<br>    vm_os_publisher                                   = optional(string)<br>    vm_os_simple                                      = optional(string)<br>    vm_os_sku                                         = optional(string)<br>    vm_os_version                                     = optional(string)<br>    spot_restore = optional(object({<br>      enabled = optional(bool)<br>      timeout = optional(number)<br>    }))<br>    scale_in = optional(object({<br>      rule                   = optional(string)<br>      force_deletion_enabled = optional(string)<br>    }))<br>    gallery_applications = optional(list(object({<br>      version_id             = string<br>      configuration_blob_uri = optional(string)<br>      order                  = optional(number)<br>      tag                    = optional(string)<br>    })))<br>    plan = optional(object({<br>      name      = optional(string)<br>      product   = optional(string)<br>      publisher = optional(string)<br>    }))<br>    source_image_reference = optional(object({<br>      publisher = optional(string)<br>      offer     = optional(string)<br>      sku       = optional(string)<br>      version   = optional(string)<br>    }))<br>    single_placement_group     = optional(bool)<br>    source_image_id            = optional(string)<br>    vtpm_enabled               = optional(bool)<br>    zone_balance               = optional(bool)<br>    zones                      = optional(list(string))<br>    encryption_at_host_enabled = optional(bool)<br>    provision_vm_agent         = optional(bool)<br>    additional_unattend_content = optional(list(object({<br>      content = string<br>      setting = string<br>    })))<br>    winrm_listener = optional(list(object({<br>      protocol        = string<br>      certificate_url = optional(string)<br>    })))<br>    rolling_upgrade_policy = optional(object({<br>      max_batch_instance_percent              = optional(number)<br>      max_unhealthy_instance_percent          = optional(number)<br>      max_unhealthy_upgraded_instance_percent = optional(number)<br>      pause_time_between_batches              = optional(string)<br>    }))<br>    termination_notification = optional(object({<br>      enabled = optional(bool)<br>      timeout = optional(string)<br>    }))<br>    secrets = optional(list(object({<br>      key_vault_id = string<br>      certificates = list(object({<br>        store = string<br>        url   = string<br>      }))<br>    })))<br>    os_disk = object({<br>      caching                          = optional(string, "ReadWrite")<br>      storage_account_type             = optional(string)<br>      disk_size_gb                     = optional(number)<br>      disk_encryption_set_id           = optional(string)<br>      secure_vm_disk_encryption_set_id = optional(string)<br>      security_encryption_type         = optional(string)<br>      write_accelerator_enabled        = optional(bool)<br>      diff_disk_settings = optional(object({<br>        option    = string<br>        placement = optional(string)<br>      }))<br>    })<br>    data_disk = optional(list(object({<br>      lun                       = number<br>      caching                   = optional(string)<br>      storage_account_type      = optional(string)<br>      disk_size_gb              = optional(number)<br>      write_accelerator_enabled = optional(bool)<br>      disk_encryption_set_id    = optional(string)<br>    })))<br>    extension = optional(list(object({<br>      name                       = string<br>      publisher                  = string<br>      type                       = string<br>      type_handler_version       = string<br>      auto_upgrade_minor_version = optional(bool)<br>      automatic_upgrade_enabled  = optional(bool)<br>      force_update_tag           = optional(string)<br>      provision_after_extensions = optional(list(string))<br>      settings                   = optional(string)<br>      protected_settings         = optional(string)<br>      protected_settings_from_key_vault = optional(object({<br>        secret_url      = optional(string)<br>        source_vault_id = optional(string)<br>      }))<br>    })))<br>    boot_diagnostics_storage_account_uri = optional(string, null)<br>    additional_capabilities = optional(object({<br>      ultra_ssd_enabled = optional(bool)<br>    }))<br>    automatic_os_upgrade_policy = optional(object({<br>      disable_automatic_rollback  = optional(bool)<br>      enable_automatic_os_upgrade = optional(bool)<br>    }))<br>    automatic_instance_repair = optional(object({<br>      enabled      = optional(bool)<br>      grace_period = optional(string)<br>    }))<br>    network_interface = optional(list(object({<br>      name                          = optional(string)<br>      primary                       = optional(bool)<br>      network_security_group_id     = optional(string)<br>      enable_accelerated_networking = optional(bool)<br>      enable_ip_forwarding          = optional(bool)<br>      dns_servers                   = optional(list(string))<br>      ip_configuration = optional(list(object({<br>        name                                         = optional(string)<br>        primary                                      = optional(bool)<br>        application_gateway_backend_address_pool_ids = optional(list(string))<br>        application_security_group_ids               = optional(list(string))<br>        load_balancer_backend_address_pool_ids       = optional(list(string))<br>        load_balancer_inbound_nat_rules_ids          = optional(list(string))<br>        version                                      = optional(string)<br>        subnet_id                                    = optional(string)<br>        public_ip_address = optional(object({<br>          name                    = optional(string)<br>          domain_name_label       = optional(string)<br>          idle_timeout_in_minutes = optional(number)<br>          public_ip_prefix_id     = optional(string)<br>          ip_tag = optional(list(object({<br>            type = optional(string)<br>            tag  = optional(string)<br>          })))<br>        }))<br>      })))<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to the resource | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ss_id"></a> [ss\_id](#output\_ss\_id) | The name of the scale set |
| <a name="output_ss_identity"></a> [ss\_identity](#output\_ss\_identity) | The identity block of the scale set |
| <a name="output_ss_name"></a> [ss\_name](#output\_ss\_name) | The name of the scale set |
| <a name="output_unique_ss_id"></a> [unique\_ss\_id](#output\_unique\_ss\_id) | The id of the scale set |
