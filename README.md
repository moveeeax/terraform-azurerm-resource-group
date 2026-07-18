# terraform-azurerm-resource-group

Terraform module that manages an [Azure](https://azure.microsoft.com/) resource
group. A resource group is a logical container into which other Azure resources
are deployed and managed, sharing a common lifecycle, region and tag set.

## Usage

```hcl
module "resource_group" {
  source = "github.com/cybercapybara/terraform-azurerm-resource-group"

  name     = "prod-rg"
  location = "eastus"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name       | Description                                            | Type          | Default | Required |
|------------|--------------------------------------------------------|---------------|---------|:--------:|
| `name`     | Name of the resource group.                            | `string`      | n/a     |   yes    |
| `location` | Azure region in which to create the resource group.    | `string`      | n/a     |   yes    |
| `tags`     | Map of tags applied to the resource group.             | `map(string)` | `{}`    |    no    |

## Outputs

| Name       | Description                            |
|------------|----------------------------------------|
| `id`       | ID of the resource group.              |
| `name`     | Name of the resource group.            |
| `location` | Azure region of the resource group.    |

## License

[MIT](LICENSE)
