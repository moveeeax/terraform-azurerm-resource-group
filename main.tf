resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location

  tags = var.tags
}

# Deleting a resource group deletes every resource inside it. An optional
# management lock lets callers make that irreversible mistake impossible for
# groups that hold anything worth keeping.
resource "azurerm_management_lock" "this" {
  count = var.lock_level == null ? 0 : 1

  name       = coalesce(var.lock_name, "${var.name}-lock")
  scope      = azurerm_resource_group.this.id
  lock_level = var.lock_level
  notes      = var.lock_notes
}
