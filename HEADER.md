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
