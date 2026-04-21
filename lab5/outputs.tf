output "core_vpc_id" {
  value = aws_vpc.core.id
}

output "manu_vpc_id" {
  value = aws_vpc.manu.id
}

output "peering_id" {
  value = aws_vpc_peering_connection.peer.id
}