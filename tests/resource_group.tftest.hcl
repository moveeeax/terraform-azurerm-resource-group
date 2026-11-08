# Runs with `terraform test` against a mocked provider, so it needs no Azure
# credentials and no network access.
#
# `mock_provider` requires Terraform >= 1.7. That is a requirement of this test
# file only — the module itself still supports >= 1.5, so versions.tf is
# deliberately left alone.

mock_provider "azurerm" {
  # azurerm_role_assignment parses its scope as an ARM ID during plan, so the
  # mocked group needs a well-formed ID instead of a random string.
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg"
    }
  }
}

variables {
  name     = "example-rg"
  location = "eastus"
}

run "defaults_create_no_lock" {
  assert {
    condition     = azurerm_resource_group.this.name == "example-rg"
    error_message = "The resource group name should be passed through unchanged."
  }

  assert {
    condition     = azurerm_resource_group.this.location == "eastus"
    error_message = "The resource group location should be passed through unchanged."
  }

  assert {
    condition     = azurerm_resource_group.this.tags != null && length(azurerm_resource_group.this.tags) == 0
    error_message = "Tags should default to an empty map, not null."
  }

  assert {
    condition     = length(azurerm_management_lock.this) == 0
    error_message = "No management lock should be created when lock_level is null."
  }

  assert {
    condition     = output.lock_id == null
    error_message = "The lock_id output should be null when no lock is created."
  }
}

run "tags_are_passed_through" {
  variables {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }

  assert {
    condition     = azurerm_resource_group.this.tags["Environment"] == "production"
    error_message = "Caller-supplied tags should reach the resource group."
  }

  assert {
    condition     = length(azurerm_resource_group.this.tags) == 2
    error_message = "The module should not silently inject extra tags."
  }
}

run "accepts_name_at_maximum_length" {
  command = plan

  variables {
    # 90 characters is exactly Azure's limit and must still be accepted.
    name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  assert {
    condition     = length(azurerm_resource_group.this.name) == 90
    error_message = "A 90-character name is valid and must not be rejected."
  }
}

run "cannot_delete_lock_is_created_and_named" {
  variables {
    lock_level = "CanNotDelete"
  }

  assert {
    condition     = length(azurerm_management_lock.this) == 1
    error_message = "A management lock should be created when lock_level is set."
  }

  assert {
    condition     = azurerm_management_lock.this[0].lock_level == "CanNotDelete"
    error_message = "The lock level should be passed through unchanged."
  }

  assert {
    condition     = azurerm_management_lock.this[0].name == "example-rg-lock"
    error_message = "The lock name should default to \"<name>-lock\"."
  }

  assert {
    condition     = azurerm_management_lock.this[0].scope == azurerm_resource_group.this.id
    error_message = "The lock must be scoped to the resource group it protects."
  }
}

run "lock_name_and_notes_can_be_overridden" {
  variables {
    lock_level = "ReadOnly"
    lock_name  = "frozen"
    lock_notes = "Managed by platform team."
  }

  assert {
    condition     = azurerm_management_lock.this[0].name == "frozen"
    error_message = "An explicit lock_name should win over the default."
  }

  assert {
    condition     = azurerm_management_lock.this[0].notes == "Managed by platform team."
    error_message = "Lock notes should be passed through unchanged."
  }
}

run "rejects_name_that_is_too_long" {
  command = plan

  variables {
    # Azure caps resource group names at 90 characters.
    name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  expect_failures = [var.name]
}

run "rejects_name_with_invalid_characters" {
  command = plan

  variables {
    name = "prod rg!"
  }

  expect_failures = [var.name]
}

run "rejects_name_ending_in_a_period" {
  command = plan

  variables {
    name = "prod-rg."
  }

  expect_failures = [var.name]
}

run "rejects_empty_name" {
  command = plan

  variables {
    name = ""
  }

  expect_failures = [var.name]
}

run "rejects_blank_location" {
  command = plan

  variables {
    location = "   "
  }

  expect_failures = [var.location]
}

run "rejects_invalid_lock_level" {
  command = plan

  variables {
    lock_level = "DoNotDelete"
  }

  expect_failures = [var.lock_level]
}

run "no_role_assignments_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_role_assignment.this) == 0
    error_message = "No role assignments should be created unless role_assignments is set."
  }

  assert {
    condition     = output.role_assignment_ids == {}
    error_message = "role_assignment_ids should be empty when no role assignments are declared."
  }
}

run "role_assignments_by_name_and_id" {
  variables {
    role_assignments = {
      team_contributor = {
        role_definition_id_or_name = "Contributor"
        principal_id               = "11111111-1111-1111-1111-111111111111"
        principal_type             = "Group"
      }
      app_reader = {
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        principal_id               = "22222222-2222-2222-2222-222222222222"
        condition                  = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'logs'"
      }
    }
  }

  assert {
    condition     = length(azurerm_role_assignment.this) == 2
    error_message = "One role assignment should be created per role_assignments entry."
  }

  assert {
    condition     = azurerm_role_assignment.this["team_contributor"].scope == azurerm_resource_group.this.id
    error_message = "Role assignments must be scoped to the resource group."
  }

  assert {
    condition     = azurerm_role_assignment.this["team_contributor"].role_definition_name == "Contributor"
    error_message = "A role name should be passed as role_definition_name."
  }

  assert {
    condition     = azurerm_role_assignment.this["team_contributor"].principal_type == "Group"
    error_message = "principal_type should be passed through unchanged."
  }

  assert {
    condition     = azurerm_role_assignment.this["team_contributor"].condition == null
    error_message = "No condition should be set unless one is given."
  }

  assert {
    condition     = azurerm_role_assignment.this["app_reader"].role_definition_id == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    error_message = "A role definition ID should be passed as role_definition_id."
  }

  assert {
    condition     = azurerm_role_assignment.this["app_reader"].condition_version == "2.0"
    error_message = "condition_version should default to 2.0 when a condition is set."
  }

  assert {
    condition     = keys(output.role_assignment_ids) == ["app_reader", "team_contributor"]
    error_message = "role_assignment_ids should be keyed like the input map."
  }
}

run "rejects_role_assignment_without_principal" {
  command = plan

  variables {
    role_assignments = {
      broken = {
        role_definition_id_or_name = "Reader"
        principal_id               = ""
      }
    }
  }

  expect_failures = [var.role_assignments]
}

run "rejects_invalid_principal_type" {
  command = plan

  variables {
    role_assignments = {
      broken = {
        role_definition_id_or_name = "Reader"
        principal_id               = "11111111-1111-1111-1111-111111111111"
        principal_type             = "Robot"
      }
    }
  }

  expect_failures = [var.role_assignments]
}

run "rejects_condition_version_without_condition" {
  command = plan

  variables {
    role_assignments = {
      broken = {
        role_definition_id_or_name = "Reader"
        principal_id               = "11111111-1111-1111-1111-111111111111"
        condition_version          = "2.0"
      }
    }
  }

  expect_failures = [var.role_assignments]
}
