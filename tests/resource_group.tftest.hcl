# Runs with `terraform test` against a mocked provider, so it needs no Azure
# credentials and no network access.
#
# `mock_provider` requires Terraform >= 1.7. That is a requirement of this test
# file only — the module itself still supports >= 1.5, so versions.tf is
# deliberately left alone.

mock_provider "azurerm" {}

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
