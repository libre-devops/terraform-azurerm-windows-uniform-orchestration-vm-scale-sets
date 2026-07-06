<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Windows Uniform Orchestration VM Scale Sets

Uniform-orchestration Windows virtual machine scale sets with Trusted Launch and automatic-update
defaults, the image catalog, Spot capacity, and rolling and automatic OS upgrades first-class.

[![CI](https://github.com/libre-devops/terraform-azurerm-windows-uniform-orchestration-vm-scale-sets/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-windows-uniform-orchestration-vm-scale-sets/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-windows-uniform-orchestration-vm-scale-sets?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-windows-uniform-orchestration-vm-scale-sets/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-windows-uniform-orchestration-vm-scale-sets)](./LICENSE)

---

## Overview

Uniform-orchestration Windows scale sets (`azurerm_windows_virtual_machine_scale_set`) keyed by
name. For Linux use the
[`uniform-linux`](https://github.com/libre-devops/terraform-azurerm-linux-uniform-orchestration-vm-scale-sets)
sibling, and for the flexible orchestration mode (mixed sizes, Spot and Regular in one set) use
[`flexible-orchestration`](https://github.com/libre-devops/terraform-azurerm-flexible-orchestration-vm-scale-sets).

What the module adds over the bare resource:

- **Sensible secure defaults**: Trusted Launch on (secure boot + vTPM; every catalog image is Gen2
  and Trusted Launch capable), automatic updates on (turning them off is a checked opt-out), a
  system-assigned identity, zone-redundant, and managed boot diagnostics.
- **The image catalog**: `source_image_simple = "WindowsServer2022AzureEdition"` instead of a
  publisher/offer/sku hunt, marketplace-verified entries. `source_image_reference` and
  `source_image_id` remain first-class.
- **Ergonomics with full coverage**: single NIC and single ip configuration are primary
  automatically; `custom_data` and `user_data` are base64-encoded for you. Spot with
  `spot_restore`, rolling and automatic OS upgrade policies, automatic instance repair, scale-in
  policy, WinRM listeners, unattend content, gallery applications, and Key Vault certificates are
  all exposed.
- **Plan-time truth**: exactly one image source, the Windows 9-character computer name prefix
  limit (including the fallback to the scale set name), Spot-only fields on Spot, rolling policy
  only with Rolling mode, automatic OS upgrades only with a health signal, and unambiguous primary
  NICs are all validated; `check` blocks flag automatic-update and Trusted Launch opt-outs and
  instance repair without a health signal.

The resource group is passed by id and parsed.

## Usage

```hcl
module "windows_vmss" {
  source  = "libre-devops/windows-uniform-orchestration-vm-scale-sets/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  scale_sets = {
    "vmssldouksprd001" = {
      sku       = "Standard_D2lds_v6"
      instances = 2

      source_image_simple = "WindowsServer2022AzureEdition"

      admin_username       = "azureadmin"
      admin_password       = var.admin_password
      computer_name_prefix = "prdwin"

      network_interfaces = {
        "nic" = {
          ip_configurations = {
            "internal" = {
              subnet_id                              = module.network.subnet_ids["snet-app-vnet-ldo-uks-prd-001"]
              load_balancer_backend_address_pool_ids = [module.private_lb.backend_pool_ids["lbi-ldo-uks-prd-001/app"]]
            }
          }
        }
      }
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - one scale set, one instance, catalog image, module
  defaults, generated password.
- [`examples/complete`](./examples/complete) - the full appliable surface: calculated subnets (the
  subnet-calculator module), a set on a private load balancer pool with an Application Health
  extension, automatic instance repair and OS upgrades, a WinRM listener, a scale-in policy,
  termination notification, and a data disk. Spot, rolling upgrades, unattend content, and Key
  Vault certificates are covered by the mocked tests.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0, < 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_marketplace_agreement.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
| [azurerm_windows_virtual_machine_scale_set.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine_scale_set) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region for the scale sets. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource id of the resource group the scale sets are created in. The resource group name and subscription are parsed from this id. | `string` | n/a | yes |
| <a name="input_scale_sets"></a> [scale\_sets](#input\_scale\_sets) | Uniform-orchestration Windows virtual machine scale sets keyed by name (vmssldouksprd001, the<br/>no-dash convention). Highlights:<br/>  sku / instances          The size and instance count.<br/>  zones                    Zone-redundant ["1", "2", "3"] by default; set [] for regions<br/>                           without zones.<br/>  Authentication           admin\_username plus admin\_password (required by the resource);<br/>                           computer\_name\_prefix must be 9 characters or fewer (validated;<br/>                           falls back to the scale set name).<br/>  Trusted Launch           secure\_boot\_enabled and vtpm\_enabled default true; every catalog<br/>                           image is Gen2 and Trusted Launch capable.<br/>  source\_image\_simple      A catalog key (see image\_catalog\_keys output); or<br/>                           source\_image\_reference / source\_image\_id. Catalog plans (Rocky)<br/>                           flow through; accept\_marketplace\_agreement = true accepts the terms<br/>                           on first use.<br/>  network\_interfaces       Map keyed by NIC name; each carries ip\_configurations keyed by<br/>                           name (subnet\_id plus optional load balancer pools and inbound NAT<br/>                           rules, application gateway pools, ASGs, and an inline public ip per<br/>                           instance). Single NIC and single ip configuration are primary<br/>                           automatically.<br/>  upgrade\_mode             Manual (provider default), Automatic, or Rolling;<br/>                           rolling\_upgrade\_policy requires Rolling, and automatic OS upgrades<br/>                           (automatic\_os\_upgrade\_policy) need a health probe or extension.<br/>  priority                 Regular (default) or Spot (with eviction\_policy, max\_bid\_price,<br/>                           and spot\_restore). | <pre>map(object({<br/>    sku       = string<br/>    instances = optional(number, 1)<br/><br/>    zones                       = optional(set(string), ["1", "2", "3"])<br/>    zone_balance                = optional(bool)<br/>    platform_fault_domain_count = optional(number)<br/>    single_placement_group      = optional(bool)<br/>    overprovision               = optional(bool)<br/>    tags                        = optional(map(string))<br/><br/>    admin_username       = string<br/>    admin_password       = string<br/>    computer_name_prefix = optional(string)<br/><br/>    enable_automatic_updates = optional(bool, true)<br/>    timezone                 = optional(string)<br/>    license_type             = optional(string)<br/><br/>    additional_unattend_content = optional(list(object({<br/>      content = string<br/>      setting = string<br/>    })), [])<br/><br/>    winrm_listeners = optional(list(object({<br/>      protocol        = string<br/>      certificate_url = optional(string)<br/>    })), [])<br/><br/>    source_image_simple = optional(string)<br/>    source_image_id     = optional(string)<br/>    source_image_reference = optional(object({<br/>      publisher = string<br/>      offer     = string<br/>      sku       = string<br/>      version   = optional(string, "latest")<br/>    }))<br/>    plan = optional(object({<br/>      name      = string<br/>      product   = string<br/>      publisher = string<br/>    }))<br/>    accept_marketplace_agreement = optional(bool, false)<br/><br/>    os_disk = optional(object({<br/>      caching                          = optional(string, "ReadWrite")<br/>      storage_account_type             = optional(string, "StandardSSD_LRS")<br/>      disk_size_gb                     = optional(number)<br/>      disk_encryption_set_id           = optional(string)<br/>      secure_vm_disk_encryption_set_id = optional(string)<br/>      security_encryption_type         = optional(string)<br/>      write_accelerator_enabled        = optional(bool, false)<br/>      diff_disk_settings = optional(object({<br/>        option    = string<br/>        placement = optional(string)<br/>      }))<br/>    }), {})<br/><br/>    data_disks = optional(list(object({<br/>      caching                        = optional(string, "ReadWrite")<br/>      storage_account_type           = optional(string, "StandardSSD_LRS")<br/>      disk_size_gb                   = number<br/>      lun                            = optional(number)<br/>      name                           = optional(string)<br/>      create_option                  = optional(string)<br/>      disk_encryption_set_id         = optional(string)<br/>      ultra_ssd_disk_iops_read_write = optional(number)<br/>      ultra_ssd_disk_mbps_read_write = optional(number)<br/>      write_accelerator_enabled      = optional(bool)<br/>    })), [])<br/><br/>    network_interfaces = map(object({<br/>      primary                        = optional(bool)<br/>      accelerated_networking_enabled = optional(bool, false)<br/>      ip_forwarding_enabled          = optional(bool, false)<br/>      dns_servers                    = optional(list(string))<br/>      network_security_group_id      = optional(string)<br/>      auxiliary_mode                 = optional(string)<br/>      auxiliary_sku                  = optional(string)<br/>      ip_configurations = map(object({<br/>        subnet_id                                    = string<br/>        primary                                      = optional(bool)<br/>        version                                      = optional(string)<br/>        load_balancer_backend_address_pool_ids       = optional(set(string))<br/>        load_balancer_inbound_nat_rules_ids          = optional(set(string))<br/>        application_gateway_backend_address_pool_ids = optional(set(string))<br/>        application_security_group_ids               = optional(set(string))<br/>        public_ip_address = optional(object({<br/>          name                    = string<br/>          domain_name_label       = optional(string)<br/>          idle_timeout_in_minutes = optional(number)<br/>          public_ip_prefix_id     = optional(string)<br/>          version                 = optional(string)<br/>          ip_tags = optional(list(object({<br/>            tag  = string<br/>            type = string<br/>          })), [])<br/>        }))<br/>      }))<br/>    }))<br/><br/>    extensions = optional(map(object({<br/>      publisher                  = string<br/>      type                       = string<br/>      type_handler_version       = string<br/>      auto_upgrade_minor_version = optional(bool, true)<br/>      automatic_upgrade_enabled  = optional(bool)<br/>      force_update_tag           = optional(string)<br/>      settings                   = optional(string)<br/>      protected_settings         = optional(string)<br/>      provision_after_extensions = optional(list(string))<br/>      protected_settings_from_key_vault = optional(object({<br/>        secret_url      = string<br/>        source_vault_id = string<br/>      }))<br/>    })), {})<br/><br/>    identity = optional(object({<br/>      type         = optional(string, "SystemAssigned")<br/>      identity_ids = optional(set(string))<br/>    }), {})<br/><br/>    boot_diagnostics = optional(object({<br/>      enabled             = optional(bool, true)<br/>      storage_account_uri = optional(string)<br/>    }), {})<br/><br/>    secure_boot_enabled        = optional(bool, true)<br/>    vtpm_enabled               = optional(bool, true)<br/>    encryption_at_host_enabled = optional(bool)<br/><br/>    priority        = optional(string, "Regular")<br/>    eviction_policy = optional(string)<br/>    max_bid_price   = optional(number)<br/>    spot_restore = optional(object({<br/>      enabled = optional(bool, true)<br/>      timeout = optional(string)<br/>    }))<br/><br/>    upgrade_mode    = optional(string)<br/>    health_probe_id = optional(string)<br/>    rolling_upgrade_policy = optional(object({<br/>      max_batch_instance_percent              = optional(number, 20)<br/>      max_unhealthy_instance_percent          = optional(number, 20)<br/>      max_unhealthy_upgraded_instance_percent = optional(number, 20)<br/>      pause_time_between_batches              = optional(string, "PT30S")<br/>      cross_zone_upgrades_enabled             = optional(bool)<br/>      maximum_surge_instances_enabled         = optional(bool)<br/>      prioritize_unhealthy_instances_enabled  = optional(bool)<br/>    }))<br/>    automatic_os_upgrade_policy = optional(object({<br/>      disable_automatic_rollback  = optional(bool, false)<br/>      enable_automatic_os_upgrade = optional(bool, true)<br/>    }))<br/>    automatic_instance_repair = optional(object({<br/>      enabled      = bool<br/>      grace_period = optional(string)<br/>      action       = optional(string)<br/>    }))<br/><br/>    scale_in = optional(object({<br/>      rule                   = optional(string)<br/>      force_deletion_enabled = optional(bool)<br/>    }))<br/><br/>    gallery_applications = optional(list(object({<br/>      version_id             = string<br/>      configuration_blob_uri = optional(string)<br/>      order                  = optional(number)<br/>      tag                    = optional(string)<br/>    })), [])<br/><br/>    secrets = optional(list(object({<br/>      key_vault_id = string<br/>      certificates = list(object({<br/>        store = string<br/>        url   = string<br/>      }))<br/>    })), [])<br/><br/>    termination_notification = optional(object({<br/>      enabled = bool<br/>      timeout = optional(string)<br/>    }))<br/><br/>    custom_data                                       = optional(string)<br/>    user_data                                         = optional(string)<br/>    ultra_ssd_enabled                                 = optional(bool)<br/>    capacity_reservation_group_id                     = optional(string)<br/>    proximity_placement_group_id                      = optional(string)<br/>    host_group_id                                     = optional(string)<br/>    edge_zone                                         = optional(string)<br/>    provision_vm_agent                                = optional(bool, true)<br/>    do_not_run_extensions_on_overprovisioned_machines = optional(bool)<br/>    extension_operations_enabled                      = optional(bool)<br/>    extensions_time_budget                            = optional(string)<br/>    resilient_vm_creation_enabled                     = optional(bool)<br/>    resilient_vm_deletion_enabled                     = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the scale sets (merged with per-scale-set tags). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_identities"></a> [identities](#output\_identities) | Map of scale set name to its identity { principal\_id, tenant\_id } (principal\_id is populated for system-assigned identities). |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of scale set name to its resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of scale set name to a { name, id } object, for passing where both are needed together. |
| <a name="output_image_catalog_keys"></a> [image\_catalog\_keys](#output\_image\_catalog\_keys) | The friendly image keys accepted by source\_image\_simple. |
| <a name="output_names"></a> [names](#output\_names) | The scale set names. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name parsed from resource\_group\_id. |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription id parsed from resource\_group\_id. |
| <a name="output_tags"></a> [tags](#output\_tags) | The base tags applied to the scale sets. |
| <a name="output_unique_ids"></a> [unique\_ids](#output\_unique\_ids) | Map of scale set name to its Azure unique id. |
<!-- END_TF_DOCS -->
