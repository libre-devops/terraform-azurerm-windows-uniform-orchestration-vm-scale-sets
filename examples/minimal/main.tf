locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_name = "vnet-${var.short}-${var.loc}-${terraform.workspace}-001"
  vmss_name = "vmss${var.short}${var.loc}${terraform.workspace}001"
  snet_app  = "snet-app-${local.vnet_name}"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

module "network" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  vnet_name     = local.vnet_name
  address_space = ["10.0.0.0/16"]
  subnets       = { (local.snet_app) = { address_prefixes = ["10.0.1.0/24"] } }
}

resource "random_password" "admin" {
  length      = 24
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

# Minimal call: one uniform Windows scale set, one instance, one NIC, a generated password, an
# image from the catalog, and the module defaults (zone-redundant, Trusted Launch on, automatic
# updates on, managed boot diagnostics). The computer name prefix must be 9 characters or fewer,
# so it cannot fall back to the 16-character scale set name.
module "windows_vmss" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  scale_sets = {
    (local.vmss_name) = {
      sku       = "Standard_D2lds_v6"
      instances = 1

      source_image_simple = "WindowsServer2022AzureEdition"

      admin_username       = "azureadmin"
      admin_password       = random_password.admin.result
      computer_name_prefix = "uniwin"

      network_interfaces = {
        "nic" = {
          ip_configurations = {
            "internal" = { subnet_id = module.network.subnet_ids[local.snet_app] }
          }
        }
      }
    }
  }
}
