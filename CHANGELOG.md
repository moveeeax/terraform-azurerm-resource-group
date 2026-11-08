# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-08

### Added

- `role_assignments` input creates `azurerm_role_assignment` resources scoped
  to the resource group. Each entry takes `role_definition_id_or_name` (a role
  name or a full role definition ID), `principal_id`, and optional
  `principal_type`, `description`, `condition` and `condition_version`
  (defaults to `"2.0"` when `condition` is set). New `role_assignment_ids`
  output. Defaults to `{}`, so existing deployments plan the same.

### Changed

- Breaking: the azurerm floor is raised from 3.0 to 3.87.0, the first release
  where `azurerm_role_assignment.principal_type` can be set. Consumers on
  azurerm 3.0-3.86 must upgrade the provider first.

## [1.1.0] - 2026-11-05

### Changed

- Bound azurerm to `>= 3.0, < 6.0`; CI also validates and tests the declared
  floor.
- CI: bump actions to their current majors, pin OpenTofu, restrict the workflow
  token to `contents: read`, add Dependabot.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-resource-group/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/moveeeax/terraform-azurerm-resource-group/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-resource-group/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-resource-group/releases/tag/v1.0.0
