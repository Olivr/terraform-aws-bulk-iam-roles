output "arn" {
  value       = { for role in aws_iam_role.roles : role.name => role.arn }
  description = "ARNs for each of the created roles"
}
