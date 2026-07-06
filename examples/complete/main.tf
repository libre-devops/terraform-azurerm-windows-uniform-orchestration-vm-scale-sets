locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  vnet_name = "vnet-${var.short}-${var.loc}-${terraform.workspace}-002"
  lb_name   = "lbi-${var.short}-${var.loc}-${terraform.workspace}-002"
  vmss_name = "vmss${var.short}${var.loc}${terraform.workspace}002"
  snet_app  = "snet-app-${local.vnet_name}"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-windows-uniform-orchestration-vm-scale-sets" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# The subnet layout is calculated, not hand-numbered: sequential, non-overlapping carving from the
# base CIDR, named from purpose plus the vnet name. Its network_subnets output drops straight into
# the network module.
module "subnet_calculator" {
  source  = "libre-devops/subnet-calculator/azurerm"
  version = "~> 4.0"

  base_cidr = "10.0.0.0/16"
  vnet_name = local.vnet_name

  subnets = [
    { purpose = "app", size = 24 }
  ]
}

module "network" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  vnet_name     = local.vnet_name
  address_space = [module.subnet_calculator.base_cidr]
  subnets       = module.subnet_calculator.network_subnets
}

# An internal load balancer whose backend pool the scale set joins.
module "private_lb" {
  source  = "libre-devops/private-lb/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  lbs = {
    (local.lb_name) = {
      frontend_ip_configurations = {
        "internal" = { subnet_id = module.network.subnet_ids[local.snet_app] }
      }
      backend_pools = { "app" = {} }
      probes        = { "tcp-8080" = { port = 8080 } }
      rules = {
        "app-8080" = {
          frontend_port     = 80
          backend_port      = 8080
          backend_pool_keys = ["app"]
          probe_key         = "tcp-8080"
        }
      }
    }
  }
}

resource "random_password" "admin" {
  length      = 24
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

# Complete call: the full appliable surface on one uniform Windows scale set: calculated subnets,
# load balancer pool membership, an Application Health extension with automatic instance repair
# and an automatic OS upgrade policy, a WinRM HTTP listener, a scale-in policy, termination
# notification, a data disk, a timezone, and accelerated networking. Spot with spot_restore,
# rolling upgrades, additional unattend content, and Key Vault certificates are covered by the
# mocked tests.
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
      timezone             = "GMT Standard Time"

      upgrade_mode  = "Automatic"
      overprovision = false

      automatic_os_upgrade_policy = {}

      os_disk = { storage_account_type = "Premium_LRS", disk_size_gb = 128 }

      data_disks = [
        { disk_size_gb = 32, create_option = "Empty" }
      ]

      winrm_listeners = [{ protocol = "Http" }]

      network_interfaces = {
        "nic" = {
          accelerated_networking_enabled = true
          ip_configurations = {
            "internal" = {
              subnet_id                              = module.network.subnet_ids[local.snet_app]
              load_balancer_backend_address_pool_ids = [module.private_lb.backend_pool_ids["${local.lb_name}/app"]]
            }
          }
        }
      }

      extensions = {
        "HealthExtension" = {
          publisher            = "Microsoft.ManagedServices"
          type                 = "ApplicationHealthWindows"
          type_handler_version = "1.0"
          settings             = jsonencode({ protocol = "tcp", port = 8080 })
        }
      }

      automatic_instance_repair = { enabled = true, grace_period = "PT10M" }
      termination_notification  = { enabled = true, timeout = "PT5M" }
      scale_in                  = { rule = "NewestVM" }
    }
  }
}
