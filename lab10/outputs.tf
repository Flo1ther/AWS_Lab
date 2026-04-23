output "az104_10_vm0_id" {
  value = aws_instance.az104_10_vm0.id
}

output "az104_10_vm0_public_ip" {
  value = aws_instance.az104_10_vm0.public_ip
}

output "az104_rsv_region1_name" {
  value = aws_backup_vault.az104_rsv_region1.name
}

output "az104_rsv_region2_name" {
  value = aws_backup_vault.az104_rsv_region2.name
}

output "az104_backup_plan_id" {
  value = aws_backup_plan.az104_backup.id
}