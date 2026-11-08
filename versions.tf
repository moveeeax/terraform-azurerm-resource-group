terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # `azurerm_role_assignment.principal_type` became settable in 3.87.0;
      # before that it was computed only.
      version = ">= 3.87.0, < 6.0"
    }
  }
}
