output "bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket hosting the website"
  value       = aws_s3_bucket.this.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.this.arn
}

output "website_url" {
  description = "Full HTTPS URL of the website"
  value       = "https://${var.domain_name}"
}

output "deployment_commands" {
  description = "Commands to deploy the website and invalidate the cache"
  value = {
    sync_command         = "aws s3 sync ./build s3://${aws_s3_bucket.this.id} --delete"
    invalidation_command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.this.id} --paths \"/*\""
  }
}
