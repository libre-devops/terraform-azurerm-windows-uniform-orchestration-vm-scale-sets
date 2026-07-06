# Uniform-orchestration Windows virtual machine scale sets keyed by name. Sensible secure defaults:
# Trusted Launch on (secure boot + vTPM; every catalog image is Gen2 and Trusted Launch capable),
# automatic updates on, a system-assigned identity, zone-redundant, and managed boot diagnostics. Spot capacity with spot_restore, rolling and automatic OS upgrades,
# automatic instance repair, scale-in policy, and gallery applications are all first-class. The
# resource group is passed by id and parsed.

# Marketplace plan acceptance, deduplicated per plan across scale sets.
resource "azurerm_marketplace_agreement" "this" {
  for_each = local.marketplace_agreements

  publisher = each.value.publisher
  offer     = each.value.offer
  plan      = each.value.plan
}

resource "azurerm_windows_virtual_machine_scale_set" "this" {
  for_each = var.scale_sets

  depends_on = [azurerm_marketplace_agreement.this]

  resource_group_name = local.rg_name
  location            = var.location
  tags                = merge(var.tags, coalesce(each.value.tags, {}))
  name                = each.key

  sku       = each.value.sku
  instances = each.value.instances

  zones                       = each.value.zones
  zone_balance                = each.value.zone_balance
  platform_fault_domain_count = each.value.platform_fault_domain_count
  single_placement_group      = each.value.single_placement_group
  overprovision               = each.value.overprovision
  edge_zone                   = each.value.edge_zone

  admin_username       = each.value.admin_username
  admin_password       = each.value.admin_password
  computer_name_prefix = each.value.computer_name_prefix

  enable_automatic_updates = each.value.enable_automatic_updates
  timezone                 = each.value.timezone
  license_type             = each.value.license_type

  secure_boot_enabled        = each.value.secure_boot_enabled
  vtpm_enabled               = each.value.vtpm_enabled
  encryption_at_host_enabled = each.value.encryption_at_host_enabled

  priority        = each.value.priority
  eviction_policy = each.value.eviction_policy
  max_bid_price   = each.value.max_bid_price

  upgrade_mode    = each.value.upgrade_mode
  health_probe_id = each.value.health_probe_id

  source_image_id = each.value.source_image_id
  custom_data     = each.value.custom_data != null ? base64encode(each.value.custom_data) : null
  user_data       = each.value.user_data != null ? base64encode(each.value.user_data) : null

  capacity_reservation_group_id                     = each.value.capacity_reservation_group_id
  proximity_placement_group_id                      = each.value.proximity_placement_group_id
  host_group_id                                     = each.value.host_group_id
  provision_vm_agent                                = each.value.provision_vm_agent
  do_not_run_extensions_on_overprovisioned_machines = each.value.do_not_run_extensions_on_overprovisioned_machines
  extension_operations_enabled                      = each.value.extension_operations_enabled
  extensions_time_budget                            = each.value.extensions_time_budget
  resilient_vm_creation_enabled                     = each.value.resilient_vm_creation_enabled
  resilient_vm_deletion_enabled                     = each.value.resilient_vm_deletion_enabled

  dynamic "additional_unattend_content" {
    for_each = each.value.additional_unattend_content

    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
    }
  }

  dynamic "winrm_listener" {
    for_each = each.value.winrm_listeners

    content {
      protocol        = winrm_listener.value.protocol
      certificate_url = winrm_listener.value.certificate_url
    }
  }

  dynamic "source_image_reference" {
    for_each = each.value.source_image_id == null ? [local.resolved_image_reference[each.key]] : []

    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  dynamic "plan" {
    for_each = local.resolved_plan[each.key] != null ? [local.resolved_plan[each.key]] : []

    content {
      name      = plan.value.name
      product   = plan.value.product
      publisher = plan.value.publisher
    }
  }

  os_disk {
    caching                          = each.value.os_disk.caching
    storage_account_type             = each.value.os_disk.storage_account_type
    disk_size_gb                     = each.value.os_disk.disk_size_gb
    disk_encryption_set_id           = each.value.os_disk.disk_encryption_set_id
    secure_vm_disk_encryption_set_id = each.value.os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = each.value.os_disk.security_encryption_type
    write_accelerator_enabled        = each.value.os_disk.write_accelerator_enabled

    dynamic "diff_disk_settings" {
      for_each = each.value.os_disk.diff_disk_settings != null ? [each.value.os_disk.diff_disk_settings] : []

      content {
        option    = diff_disk_settings.value.option
        placement = diff_disk_settings.value.placement
      }
    }
  }

  dynamic "data_disk" {
    for_each = each.value.data_disks

    content {
      caching                        = data_disk.value.caching
      storage_account_type           = data_disk.value.storage_account_type
      disk_size_gb                   = data_disk.value.disk_size_gb
      lun                            = coalesce(data_disk.value.lun, data_disk.key)
      name                           = data_disk.value.name
      create_option                  = data_disk.value.create_option
      disk_encryption_set_id         = data_disk.value.disk_encryption_set_id
      ultra_ssd_disk_iops_read_write = data_disk.value.ultra_ssd_disk_iops_read_write
      ultra_ssd_disk_mbps_read_write = data_disk.value.ultra_ssd_disk_mbps_read_write
      write_accelerator_enabled      = data_disk.value.write_accelerator_enabled
    }
  }

  dynamic "network_interface" {
    for_each = each.value.network_interfaces

    content {
      name                          = network_interface.key
      primary                       = coalesce(network_interface.value.primary, length(each.value.network_interfaces) == 1)
      enable_accelerated_networking = network_interface.value.accelerated_networking_enabled
      enable_ip_forwarding          = network_interface.value.ip_forwarding_enabled
      dns_servers                   = network_interface.value.dns_servers
      network_security_group_id     = network_interface.value.network_security_group_id
      auxiliary_mode                = network_interface.value.auxiliary_mode
      auxiliary_sku                 = network_interface.value.auxiliary_sku

      dynamic "ip_configuration" {
        for_each = network_interface.value.ip_configurations

        content {
          name                                         = ip_configuration.key
          primary                                      = coalesce(ip_configuration.value.primary, length(network_interface.value.ip_configurations) == 1)
          subnet_id                                    = ip_configuration.value.subnet_id
          version                                      = ip_configuration.value.version
          load_balancer_backend_address_pool_ids       = ip_configuration.value.load_balancer_backend_address_pool_ids
          load_balancer_inbound_nat_rules_ids          = ip_configuration.value.load_balancer_inbound_nat_rules_ids
          application_gateway_backend_address_pool_ids = ip_configuration.value.application_gateway_backend_address_pool_ids
          application_security_group_ids               = ip_configuration.value.application_security_group_ids

          dynamic "public_ip_address" {
            for_each = ip_configuration.value.public_ip_address != null ? [ip_configuration.value.public_ip_address] : []

            content {
              name                    = public_ip_address.value.name
              domain_name_label       = public_ip_address.value.domain_name_label
              idle_timeout_in_minutes = public_ip_address.value.idle_timeout_in_minutes
              public_ip_prefix_id     = public_ip_address.value.public_ip_prefix_id
              version                 = public_ip_address.value.version

              dynamic "ip_tag" {
                for_each = public_ip_address.value.ip_tags

                content {
                  tag  = ip_tag.value.tag
                  type = ip_tag.value.type
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "extension" {
    for_each = each.value.extensions

    content {
      name                       = extension.key
      publisher                  = extension.value.publisher
      type                       = extension.value.type
      type_handler_version       = extension.value.type_handler_version
      auto_upgrade_minor_version = extension.value.auto_upgrade_minor_version
      automatic_upgrade_enabled  = extension.value.automatic_upgrade_enabled
      force_update_tag           = extension.value.force_update_tag
      settings                   = extension.value.settings
      protected_settings         = extension.value.protected_settings
      provision_after_extensions = extension.value.provision_after_extensions

      dynamic "protected_settings_from_key_vault" {
        for_each = extension.value.protected_settings_from_key_vault != null ? [extension.value.protected_settings_from_key_vault] : []

        content {
          secret_url      = protected_settings_from_key_vault.value.secret_url
          source_vault_id = protected_settings_from_key_vault.value.source_vault_id
        }
      }
    }
  }

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.identity_ids
  }

  dynamic "boot_diagnostics" {
    for_each = each.value.boot_diagnostics.enabled ? [each.value.boot_diagnostics] : []

    content {
      storage_account_uri = boot_diagnostics.value.storage_account_uri
    }
  }

  dynamic "spot_restore" {
    for_each = each.value.spot_restore != null ? [each.value.spot_restore] : []

    content {
      enabled = spot_restore.value.enabled
      timeout = spot_restore.value.timeout
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = each.value.rolling_upgrade_policy != null ? [each.value.rolling_upgrade_policy] : []

    content {
      max_batch_instance_percent              = rolling_upgrade_policy.value.max_batch_instance_percent
      max_unhealthy_instance_percent          = rolling_upgrade_policy.value.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = rolling_upgrade_policy.value.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = rolling_upgrade_policy.value.pause_time_between_batches
      cross_zone_upgrades_enabled             = rolling_upgrade_policy.value.cross_zone_upgrades_enabled
      maximum_surge_instances_enabled         = rolling_upgrade_policy.value.maximum_surge_instances_enabled
      prioritize_unhealthy_instances_enabled  = rolling_upgrade_policy.value.prioritize_unhealthy_instances_enabled
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = each.value.automatic_os_upgrade_policy != null ? [each.value.automatic_os_upgrade_policy] : []

    content {
      disable_automatic_rollback  = automatic_os_upgrade_policy.value.disable_automatic_rollback
      enable_automatic_os_upgrade = automatic_os_upgrade_policy.value.enable_automatic_os_upgrade
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = each.value.automatic_instance_repair != null ? [each.value.automatic_instance_repair] : []

    content {
      enabled      = automatic_instance_repair.value.enabled
      grace_period = automatic_instance_repair.value.grace_period
      action       = automatic_instance_repair.value.action
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
    for_each = each.value.gallery_applications

    content {
      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets

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

  dynamic "termination_notification" {
    for_each = each.value.termination_notification != null ? [each.value.termination_notification] : []

    content {
      enabled = termination_notification.value.enabled
      timeout = termination_notification.value.timeout
    }
  }

  dynamic "additional_capabilities" {
    for_each = each.value.ultra_ssd_enabled != null ? [each.value.ultra_ssd_enabled] : []

    content {
      ultra_ssd_enabled = additional_capabilities.value
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.source_image_simple == null || contains(keys(local.image_catalog), coalesce(each.value.source_image_simple, "-"))
      error_message = "Scale set \"${each.key}\": source_image_simple must be one of the catalog keys: ${join(", ", sort(keys(local.image_catalog)))}."
    }
  }
}
