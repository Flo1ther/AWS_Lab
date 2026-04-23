output "vm1_id" {
  value = aws_instance.vm1.id
}

output "vm2_id" {
  value = aws_instance.vm2.id
}

output "vm1_public_ip" {
  value = aws_instance.vm1.public_ip
}

output "vm2_public_ip" {
  value = aws_instance.vm2.public_ip
}

output "ebs_volume_id" {
  value = aws_ebs_volume.vm1_disk1.id
}

output "alb_dns_name" {
  value = aws_lb.vmss_alb.dns_name
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.vmss_asg.name
}

