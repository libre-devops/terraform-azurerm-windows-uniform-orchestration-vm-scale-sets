output "ss_id" {
  value = {
    for key, value in azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set : key => value.id
  }
  description = "The name of the scale set"
}

output "ss_identity" {
  value = {
    for key, value in azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set : key => value.identity
  }
  description = "The identity block of the scale set"
}

output "ss_name" {
  value = {
    for key, value in azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set : key => value.name
  }
  description = "The name of the scale set"
}

output "unique_ss_id" {
  value = {
    for key, value in azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set : key => value.unique_id
  }
  description = "The id of the scale set"
}
