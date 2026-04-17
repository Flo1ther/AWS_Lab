output "helpdesk_role_name" {
  description = "IAM Role name for HelpDesk"
  value       = aws_iam_role.helpdesk_role.name
}

output "helpdesk_role_arn" {
  description = "IAM Role ARN"
  value       = aws_iam_role.helpdesk_role.arn
}

output "helpdesk_policy_arn" {
  description = "IAM Policy ARN"
  value       = aws_iam_policy.helpdesk_policy.arn
}