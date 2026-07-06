output "image_catalog_keys" {
  description = "Catalog keys accepted by source_image_simple."
  value       = module.windows_vmss.image_catalog_keys
}

output "vmss_ids" {
  description = "Map of scale set name to resource id."
  value       = module.windows_vmss.ids
}
