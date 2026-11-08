variable "name" {
  description = "Name of the resource group."
  type        = string

  validation {
    # Azure rejects out-of-spec names at apply time, after the plan has already
    # been reviewed and approved. Catching it during plan is far cheaper.
    condition     = can(regex("^[\\p{L}\\p{N}_()\\-.]{1,90}$", var.name))
    error_message = "The name must be 1-90 characters long and may only contain letters, numbers, underscores, parentheses, hyphens and periods."
  }

  validation {
    condition     = !endswith(var.name, ".")
    error_message = "The name must not end with a period."
  }
}

variable "location" {
  description = "Azure region in which to create the resource group, e.g. \"eastus\" or \"East US\"."
  type        = string

  validation {
    # The set of valid regions changes over time and varies by subscription, so
    # only the obviously broken case is rejected here rather than a hardcoded list.
    condition     = length(trimspace(var.location)) > 0
    error_message = "The location must be a non-empty Azure region name."
  }
}

variable "tags" {
  description = "Map of tags applied to the resource group. Azure does not propagate these to resources created inside the group."
  type        = map(string)
  default     = {}
}

variable "lock_level" {
  description = "Management lock to apply to the resource group. \"CanNotDelete\" blocks deletion of the group and everything in it; \"ReadOnly\" additionally blocks modification. Leave as null to create no lock."
  type        = string
  default     = null

  validation {
    condition     = var.lock_level == null || contains(["CanNotDelete", "ReadOnly"], coalesce(var.lock_level, "unset"))
    error_message = "The lock_level must be either \"CanNotDelete\", \"ReadOnly\" or null."
  }
}

variable "lock_name" {
  description = "Name of the management lock. Defaults to \"<name>-lock\". Ignored when lock_level is null."
  type        = string
  default     = null
}

variable "lock_notes" {
  description = "Note recorded on the management lock explaining why it exists. Ignored when lock_level is null."
  type        = string
  default     = null
}

variable "role_assignments" {
  description = "Role assignments to create on the resource group, keyed by an arbitrary static name. role_definition_id_or_name takes a role name such as \"Reader\" or a full role definition ID. principal_type (User, Group or ServicePrincipal) is optional but helps when the principal was created moments earlier, before directory replication caught up. condition_version defaults to \"2.0\" when condition is set."
  type = map(object({
    role_definition_id_or_name = string
    principal_id               = string
    principal_type             = optional(string)
    description                = optional(string)
    condition                  = optional(string)
    condition_version          = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for ra in values(var.role_assignments) : length(trimspace(ra.role_definition_id_or_name)) > 0 && length(trimspace(ra.principal_id)) > 0])
    error_message = "Each role_assignments entry needs a non-empty role_definition_id_or_name and principal_id."
  }

  validation {
    condition     = alltrue([for ra in values(var.role_assignments) : ra.principal_type == null || contains(["User", "Group", "ServicePrincipal"], coalesce(ra.principal_type, "unset"))])
    error_message = "Each role_assignments principal_type must be User, Group, ServicePrincipal or null."
  }

  validation {
    condition     = alltrue([for ra in values(var.role_assignments) : ra.condition_version == null || (ra.condition != null && contains(["1.0", "2.0"], coalesce(ra.condition_version, "unset")))])
    error_message = "A role_assignments condition_version may only be set together with condition, and must be \"1.0\" or \"2.0\"."
  }
}
