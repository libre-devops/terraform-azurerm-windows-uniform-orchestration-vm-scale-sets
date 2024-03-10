module "shared_vars" {
  source = "libre-devops/shared-vars/azurerm"
}

locals {
  lookup_cidr = {
    for landing_zone, envs in module.shared_vars.cidrs : landing_zone => {
      for env, cidr in envs : env => cidr
    }
  }
}

#
#module "subnet_calculator" {
#  source = "libre-devops/subnet-calculator/null"
#
#  base_cidr    = local.lookup_cidr[var.short][var.env][0]
#  subnet_sizes = [24] # Automatic naming as subnet1, subnet2, subnet3
#}
#

module "subnet_calculator" {
  source = "libre-devops/subnet-calculator/null"

  base_cidr = local.lookup_cidr[var.short][var.env][0]
  subnets = {
    "AzureBastionSubnet" = {
      mask_size = 26
      netnum    = 0
    }
    "subnet1" = {
      mask_size = 26
      netnum    = 1
    }
  }
}

module "rg" {
  source = "libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${var.env}-01"
  location = local.location
  tags     = local.tags
}

module "network" {
  source = "libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-01"
  vnet_location      = module.rg.rg_location
  vnet_address_space = [module.subnet_calculator.base_cidr]

  subnets = {
    for i, name in module.subnet_calculator.subnet_names :
    name => {
      address_prefixes = toset([module.subnet_calculator.subnet_ranges[i]])
    }
  }
}

module "nsg" {
  source = "libre-devops/nsg/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name              = "nsg-${var.short}-${var.loc}-${var.env}-01"
  associate_with_subnet = true
  subnet_id             = element(values(module.network.subnets_ids), 1)
  custom_nsg_rules = {
    "AllowVnetInbound" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
  }
}

module "bastion" {
  source = "libre-devops/bastion/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  bastion_host_name                  = "bst-${var.short}-${var.loc}-${var.env}-01"
  create_bastion_nsg                 = true
  create_bastion_nsg_rules           = true
  create_bastion_subnet              = false
  external_subnet_id                 = module.network.subnets_ids["AzureBastionSubnet"]
  bastion_subnet_target_vnet_name    = module.network.vnet_name
  bastion_subnet_target_vnet_rg_name = module.network.vnet_rg_name
  bastion_subnet_range               = "10.0.1.0/27"
}

resource "azurerm_application_security_group" "server_asg" {
  resource_group_name = module.rg.rg_name
  location            = module.rg.rg_location
  tags                = module.rg.rg_tags

  name = "asg-${var.short}-${var.loc}-${var.env}-01"
}


locals {
  name       = "vmss-${var.short}-${var.loc}-${var.env}01"
  admin_user = "LibreDevOpsAdmin"
}

module "windows_vm_scale_set" {
  source = "../../" # Adjust this path to where your module is located


  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  scale_sets = [
    {

      name = local.name

      computer_name_prefix            = "vmss1"
      admin_username                  = "Local${title(var.short)}${title(var.env)}Admin"
      admin_password                  = data.azurerm_key_vault_secret.admin_pwd.value
      instances                       = 2
      sku                             = "Standard_B2ms"
      vm_os_simple                    = "WindowsServer2022AzureEditionGen2"
      disable_password_authentication = true
      overprovision                   = true
      upgrade_mode                    = "Manual"
      network_interface = [
        {
          name                          = "nic-${local.name}"
          primary                       = true
          enable_accelerated_networking = false
          ip_configuration = [
            {
              name      = "ipconfig-${local.name}"
              primary   = true
              subnet_id = module.network.subnets_ids["subnet1"]
            }
          ]
        }
      ]
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
        disk_size_gb         = 127
      }

    }
  ]
}
