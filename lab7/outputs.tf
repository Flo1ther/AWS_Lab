output "s3_bucket_name" {
  value = aws_s3_bucket.storage.bucket
}

output "efs_id" {
  value = aws_efs_file_system.efs.id
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}