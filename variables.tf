variable "roles" {
  type        = map(map(list(string)))
  description = "Roles to create"
}

variable "tags" {
  type        = map(string)
  description = "Tags to add to all users"
  default     = {}
}
