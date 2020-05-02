output "arn" {
  value       = { for role in aws_iam_role.roles : role.name => role.arn }
  description = "ARNs of the input roles"
}
