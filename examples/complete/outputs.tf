output "backend_pool_ids" {
  description = "The load balancer backend pool the scale set joined."
  value       = module.private_lb.backend_pool_ids
}

output "calculated_subnets" {
  description = "The subnet CIDRs the calculator carved from the base CIDR."
  value       = module.subnet_calculator.cidrs_map
}

output "identities" {
  description = "System-assigned identity principals of the scale sets."
  value       = module.windows_vmss.identities
}

output "vmss_ids" {
  description = "Map of scale set name to resource id."
  value       = module.windows_vmss.ids
}
