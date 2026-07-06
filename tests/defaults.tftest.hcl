# Plan-time tests for the module. The provider is mocked, so no credentials, no features block,
# and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  location          = "uksouth"
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01"

  scale_sets = {
    "vmssldoukststs01" = {
      sku       = "Standard_D2lds_v6"
      instances = 1

      source_image_simple = "WindowsServer2022AzureEdition"

      admin_username       = "azureadmin"
      admin_password       = "Sup3rS3cret!!Sup3r"
      computer_name_prefix = "uniwin"

      network_interfaces = {
        "nic" = {
          ip_configurations = {
            "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" }
          }
        }
      }
    }
  }
}

# Secure defaults: Trusted Launch on, automatic updates on, system-assigned identity,
# zone-redundant, catalog resolution, primary NIC auto-marked, managed boot diagnostics.
run "secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].secure_boot_enabled == true && azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].vtpm_enabled == true
    error_message = "Trusted Launch (secure boot + vTPM) should be on by default."
  }

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].enable_automatic_updates == true
    error_message = "Automatic updates should be on by default."
  }

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].identity[0].type == "SystemAssigned"
    error_message = "A system-assigned identity should be the default."
  }

  assert {
    condition     = tolist(azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].zones) == tolist(["1", "2", "3"])
    error_message = "Scale sets should be zone-redundant by default."
  }

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].source_image_reference[0].publisher == "MicrosoftWindowsServer"
    error_message = "source_image_simple should resolve through the catalog."
  }

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].network_interface[0].primary == true
    error_message = "A single NIC should be primary automatically."
  }

  assert {
    condition     = length(azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].boot_diagnostics) == 1
    error_message = "Managed boot diagnostics should be on by default."
  }
}

# The resource group is parsed from the id and exposed as an output.
run "parses_resource_group" {
  command = plan

  assert {
    condition     = output.resource_group_name == "rg-ldo-uks-tst-01"
    error_message = "resource_group_name should be parsed from resource_group_id."
  }
}

# Validation: a computer name prefix over 9 characters is rejected (including the fallback to the
# scale set name).
run "rejects_long_computer_name_prefix" {
  command = plan

  variables {
    scale_sets = {
      "vmssldoukststs01" = {
        sku                 = "Standard_D2lds_v6"
        instances           = 1
        source_image_simple = "WindowsServer2022AzureEdition"
        admin_username      = "azureadmin"
        admin_password      = "Sup3rS3cret!!Sup3r"
        network_interfaces = {
          "nic" = {
            ip_configurations = { "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" } }
          }
        }
      }
    }
  }

  expect_failures = [var.scale_sets]
}

# Unattend content and WinRM listeners flow through (certificate-free surface).
run "unattend_and_winrm_flow" {
  command = plan

  variables {
    scale_sets = {
      "vmssldoukststs01" = {
        sku                 = "Standard_D2lds_v6"
        instances           = 1
        source_image_simple = "WindowsServer2022AzureEdition"

        admin_username       = "azureadmin"
        admin_password       = "Sup3rS3cret!!Sup3r"
        computer_name_prefix = "uniwin"

        additional_unattend_content = [{
          content = "<FirstLogonCommands></FirstLogonCommands>"
          setting = "FirstLogonCommands"
        }]

        winrm_listeners = [{ protocol = "Http" }]

        network_interfaces = {
          "nic" = {
            ip_configurations = { "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" } }
          }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].additional_unattend_content) == 1
    error_message = "additional_unattend_content should flow through."
  }

  assert {
    condition     = tolist(azurerm_windows_virtual_machine_scale_set.this["vmssldoukststs01"].winrm_listener)[0].protocol == "Http"
    error_message = "winrm_listeners should flow through."
  }
}

# Validation: automatic OS upgrades need a health signal.
run "rejects_auto_os_upgrade_without_health" {
  command = plan

  variables {
    scale_sets = {
      "vmssldoukststs01" = {
        sku                         = "Standard_D2lds_v6"
        instances                   = 1
        source_image_simple         = "WindowsServer2022AzureEdition"
        admin_username              = "azureadmin"
        admin_password              = "Sup3rS3cret!!Sup3r"
        computer_name_prefix        = "uniwin"
        automatic_os_upgrade_policy = {}
        network_interfaces = {
          "nic" = {
            ip_configurations = { "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" } }
          }
        }
      }
    }
  }

  expect_failures = [var.scale_sets]
}

# Validation: spot-only fields demand priority = Spot.
run "rejects_spot_restore_on_regular" {
  command = plan

  variables {
    scale_sets = {
      "vmssldoukststs01" = {
        sku                  = "Standard_D2lds_v6"
        instances            = 1
        source_image_simple  = "WindowsServer2022AzureEdition"
        admin_username       = "azureadmin"
        admin_password       = "Sup3rS3cret!!Sup3r"
        computer_name_prefix = "uniwin"
        spot_restore         = {}
        network_interfaces = {
          "nic" = {
            ip_configurations = { "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" } }
          }
        }
      }
    }
  }

  expect_failures = [var.scale_sets]
}

# Validation: an unknown catalog key fails the plan with the key list.
run "rejects_unknown_catalog_key" {
  command = plan

  variables {
    scale_sets = {
      "vmssldoukststs01" = {
        sku                  = "Standard_D2lds_v6"
        instances            = 1
        source_image_simple  = "NotAnImage"
        admin_username       = "azureadmin"
        admin_password       = "Sup3rS3cret!!Sup3r"
        computer_name_prefix = "uniwin"
        network_interfaces = {
          "nic" = {
            ip_configurations = { "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" } }
          }
        }
      }
    }
  }

  expect_failures = [azurerm_windows_virtual_machine_scale_set.this]
}
