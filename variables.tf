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
