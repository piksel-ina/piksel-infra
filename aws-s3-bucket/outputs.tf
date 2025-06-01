output "public_bucket_arn" {
  value = aws_s3_bucket.public.arn
}

output "public_bucket_name" {
  value = aws_s3_bucket.public.bucket
}
