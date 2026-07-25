output "id" {
  description = "ID of the resource group."
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure region of the resource group."
  value       = azurerm_resource_group.this.location
}

output "lock_id" {
  description = "ID of the management lock protecting the resource group, or null when lock_level is null."
  value       = one(azurerm_management_lock.this[*].id)
}
