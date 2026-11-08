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

# Role assignments scoped to the group, so access is declared next to the group
# it governs instead of in a separate block in the root module.
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope = azurerm_resource_group.this.id

  # A built-in or custom role can be given by name ("Reader") or by its full
  # role definition ID; only one of the two arguments may be set.
  role_definition_id   = local.role_definition_is_id[each.key] ? each.value.role_definition_id_or_name : null
  role_definition_name = local.role_definition_is_id[each.key] ? null : each.value.role_definition_id_or_name

  principal_id      = each.value.principal_id
  principal_type    = each.value.principal_type
  description       = each.value.description
  condition         = each.value.condition
  condition_version = each.value.condition == null ? null : coalesce(each.value.condition_version, "2.0")
}

locals {
  role_definition_is_id = {
    for k, v in var.role_assignments :
    k => strcontains(lower(v.role_definition_id_or_name), "/providers/microsoft.authorization/roledefinitions/")
  }
}
