locals {
  rg      = provider::azurerm::parse_resource_id(var.resource_group_id)
  rg_name = local.rg.resource_group_name

  # Catalog resolution: a missing key falls back to a placeholder so expansion never errors
  # mid-expression, and the scale set resource's precondition fails the plan with the valid key list.
  catalog_fallback = { publisher = "(unknown)", offer = "(unknown)", sku = "(unknown)", plan = null }

  resolved_image_reference = {
    for k, v in var.scale_sets : k => (
      v.source_image_simple != null
      ? {
        publisher = lookup(local.image_catalog, coalesce(v.source_image_simple, "-"), local.catalog_fallback).publisher
        offer     = lookup(local.image_catalog, coalesce(v.source_image_simple, "-"), local.catalog_fallback).offer
        sku       = lookup(local.image_catalog, coalesce(v.source_image_simple, "-"), local.catalog_fallback).sku
        version   = "latest"
      }
      : v.source_image_reference
    ) if v.source_image_id == null
  }

  # Effective marketplace plan: an explicit plan wins, otherwise a plan carried by the catalog entry
  # (Rocky) flows automatically.
  resolved_plan = {
    for k, v in var.scale_sets : k => (
      v.plan != null ? v.plan : (
        v.source_image_simple != null
        ? lookup(local.image_catalog, coalesce(v.source_image_simple, "-"), local.catalog_fallback).plan
        : null
      )
    )
  }

  # Marketplace agreements are per (publisher, product, plan), deduplicated across scale sets,
  # covering both explicit plans and catalog-carried ones.
  marketplace_agreements = {
    for item in distinct([
      for k, v in var.scale_sets : {
        publisher = local.resolved_plan[k].publisher
        offer     = local.resolved_plan[k].product
        plan      = local.resolved_plan[k].name
      } if local.resolved_plan[k] != null && v.accept_marketplace_agreement
    ]) : "${item.publisher}|${item.offer}|${item.plan}" => item
  }
}
