terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.87.0, < 6.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../.."

  name     = "example-rg"
  location = "eastus"

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "resource_group_id" {
  value = module.resource_group.id
}
