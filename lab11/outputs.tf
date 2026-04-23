output "instance_public_ip" {
  value = aws_instance.lab11_vm.public_ip
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}