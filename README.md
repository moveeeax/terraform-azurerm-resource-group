# terraform-azurerm-resource-group

Terraform module that manages an [Azure](https://azure.microsoft.com/) resource
group. A resource group is a logical container into which other Azure resources
are deployed and managed, sharing a common lifecycle, region and tag set.

## Usage

```hcl
module "resource_group" {
  source = "github.com/moveeeax/terraform-azurerm-resource-group"

  name     = "prod-rg"
  location = "eastus"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Protecting the group from deletion

Deleting a resource group deletes **every resource inside it**, and Azure asks
for no confirmation beyond the Terraform plan. Set `lock_level` to have the
module also manage an [Azure management lock](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources)
on the group:

```hcl
module "resource_group" {
  source = "github.com/moveeeax/terraform-azurerm-resource-group"

  name     = "prod-rg"
  location = "eastus"

  lock_level = "CanNotDelete"
  lock_notes = "Holds production state; delete only via a documented decommission."
}
```

`CanNotDelete` still allows resources in the group to be created and modified,
it only blocks deletion. `ReadOnly` blocks modification too, which also breaks
most day-to-day Terraform runs against resources in the group, so prefer
`CanNotDelete` unless you really mean to freeze everything.

Because the lock is managed by this module, `terraform destroy` removes the
lock before the group, so it is a guardrail against accidental portal or CLI
deletion rather than an absolute barrier. Managing the lock outside Terraform,
or adding a `prevent_destroy` lifecycle block in your root module, is the
stronger option if that is what you need.

## Validation

`name` is checked against Azure's rules at plan time (1-90 characters; letters,
numbers, underscores, parentheses, hyphens and periods; no trailing period),
rather than being rejected by the API halfway through an apply.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name         | Description                                                                                   | Type          | Default | Required |
|--------------|-----------------------------------------------------------------------------------------------|---------------|---------|:--------:|
| `name`       | Name of the resource group. 1-90 characters, no trailing period.                                | `string`      | n/a     |   yes    |
| `location`   | Azure region in which to create the resource group, e.g. `eastus` or `East US`.                 | `string`      | n/a     |   yes    |
| `tags`       | Map of tags applied to the resource group. Not propagated to resources inside it.               | `map(string)` | `{}`    |    no    |
| `lock_level` | Management lock to apply: `CanNotDelete`, `ReadOnly`, or `null` for no lock.                    | `string`      | `null`  |    no    |
| `lock_name`  | Name of the management lock. Defaults to `<name>-lock`. Ignored when `lock_level` is `null`.    | `string`      | `null`  |    no    |
| `lock_notes` | Note recorded on the management lock. Ignored when `lock_level` is `null`.                      | `string`      | `null`  |    no    |

## Outputs

| Name       | Description                                                                |
|------------|----------------------------------------------------------------------------|
| `id`       | ID of the resource group.                                                  |
| `name`     | Name of the resource group.                                                |
| `location` | Azure region of the resource group.                                        |
| `lock_id`  | ID of the management lock, or `null` when `lock_level` is `null`.          |

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test
```

`terraform test` runs against a mocked provider, so it needs no Azure
credentials and no network access. The test files require Terraform >= 1.7 for
`mock_provider`; the module itself still supports >= 1.5.

## License

[MIT](LICENSE)
