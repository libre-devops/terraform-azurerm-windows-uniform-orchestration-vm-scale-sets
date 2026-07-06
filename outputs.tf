output "identities" {
  description = "Map of scale set name to its identity { principal_id, tenant_id } (principal_id is populated for system-assigned identities)."
  value = {
    for k, v in azurerm_windows_virtual_machine_scale_set.this : k => try({
      principal_id = v.identity[0].principal_id
      tenant_id    = v.identity[0].tenant_id
    }, null)
  }
}

output "ids" {
  description = "Map of scale set name to its resource id."
  value       = { for k, v in azurerm_windows_virtual_machine_scale_set.this : k => v.id }
}

output "ids_zipmap" {
  description = "Map of scale set name to a { name, id } object, for passing where both are needed together."
  value       = { for k, v in azurerm_windows_virtual_machine_scale_set.this : k => { name = v.name, id = v.id } }
}

output "image_catalog_keys" {
  description = "The friendly image keys accepted by source_image_simple."
  value       = sort(keys(local.image_catalog))
}

output "names" {
  description = "The scale set names."
  value       = keys(azurerm_windows_virtual_machine_scale_set.this)
}

output "resource_group_name" {
  description = "Resource group name parsed from resource_group_id."
  value       = local.rg_name
}

output "subscription_id" {
  description = "Subscription id parsed from resource_group_id."
  value       = local.rg.subscription_id
}

output "tags" {
  description = "The base tags applied to the scale sets."
  value       = var.tags
}

output "unique_ids" {
  description = "Map of scale set name to its Azure unique id."
  value       = { for k, v in azurerm_windows_virtual_machine_scale_set.this : k => v.unique_id }
}
