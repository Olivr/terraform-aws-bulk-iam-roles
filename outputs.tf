output "roles" {
  value = {
    for role in aws_iam_role.roles :
    role.name => {
      name = role.name
      arn  = role.arn
    }
  }
  description = "Created roles in the format { name = { name, arn }}"
}
