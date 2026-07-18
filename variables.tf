variable "name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the resource group."
  type        = string
}

variable "tags" {
  description = "Map of tags applied to the resource group."
  type        = map(string)
  default     = {}
}
