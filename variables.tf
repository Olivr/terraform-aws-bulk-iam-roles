variable "roles" {
  type        = map(map(list(string)))
  description = "Roles to create. See [_var_roles.example.tfvars.json](_var_roles.example.tfvars.json)"
}

variable "tags" {
  type        = map(string)
  description = "Tags to add to all users"
  default     = {}
}
