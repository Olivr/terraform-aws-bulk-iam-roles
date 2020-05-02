variable "roles" {
  type        = map(map(list(string)))
  description = "Roles to create"
}
