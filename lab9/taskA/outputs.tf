
output "staging_url" {
  value = aws_elastic_beanstalk_environment.staging.cname
}