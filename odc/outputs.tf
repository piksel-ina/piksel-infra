output "odc_namespace" {
  value       = kubernetes_namespace.odc.metadata[0].name
  description = "Kubernetes namespace for ODC"
}

output "odc_write_password_secret_arn" {
  value       = aws_secretsmanager_secret.odc_write_password.arn
  description = "Secrets Manager ARN for ODC write password"
}

output "odc_read_password_secret_arn" {
  value       = aws_secretsmanager_secret.odc_read_password.arn
  description = "Secrets Manager ARN for ODC read password"
}

output "odc_write_db_password" {
  value       = aws_secretsmanager_secret_version.odc_write_password.secret_string
  description = "ODC write database password"
  sensitive   = true
}

output "odc_read_db_password" {
  value       = aws_secretsmanager_secret_version.odc_read_password.secret_string
  description = "ODC read database password"
  sensitive   = true
}

# output "ows_cache_cloudfront_domain_name" {
#   value       = aws_cloudfront_distribution.ows_cache.domain_name
#   description = "CloudFront distribution domain name for ows cache"
# }

# output "ows_cache_cloudfront_distribution_id" {
#   value       = aws_cloudfront_distribution.ows_cache.id
#   description = "CloudFront distribution ID"
# }

# output "ows_cache_certificate_arn" {
#   value       = aws_acm_certificate.ows_cache.arn
#   description = "ARN of the ACM certificate for ows cache"
# }

# output "ows_cache_dns_record" {
#   value       = aws_route53_record.ows_cache.fqdn
#   description = "FQDN of the Route53 record for ows cache"
# }

output "odc_data_reader_role_arn" {
  value       = module.iam_eks_role_bucket.iam_role_arn
  description = "IAM role ARN for ODC data reader"
}
