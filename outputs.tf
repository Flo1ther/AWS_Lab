output "users" {
  value = [
    aws_iam_user.user1.name,
    aws_iam_user.user2.name
  ]
}

output "group" {
  value = aws_iam_group.it_admins.name
}