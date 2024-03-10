output "ss_id" {
  value = {
    for key, value in element(azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set[*], 0) : key => value.id
  }
  description = "The name of the scale set"
}

output "ss_name" {
  value = {
    for key, value in element(azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set[*], 0) : key => value.name
  }
  description = "The name of the scale set"
}

#output "ss_principal_id" {
#  value = {
#    for key, value in element(azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set[*], 0) : key => element(value.identity, 0).principal_id
#  }
#  description = "Client ID of system assigned managed identity if created"
#}

output "unique_ss_id" {
  value = {
    for key, value in element(azurerm_windows_virtual_machine_scale_set.windows_vm_scale_set[*], 0) : key => value.unique_id
  }
  description = "The id of the scale set"
}
