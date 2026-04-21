output "vpc_id" {
  value = aws_vpc.core.id
}

output "subnets" {
  value = [
    aws_subnet.shared.id,
    aws_subnet.database.id
  ]
}