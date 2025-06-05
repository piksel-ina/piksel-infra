locals {
  prefix               = "${lower(var.project)}-${lower(var.environment)}"
  tags                 = var.default_tags
  odc_namespace        = "open-datacube"
  read_buckets         = concat(var.read_external_buckets, var.internal_buckets)
  service_account_name = "odc-data-reader"
  subdomain            = var.subdomains[0] # The public domain must be the first in the list
}

# --- Creates Kubernetes namespace for ODC ---
resource "kubernetes_namespace" "odc" {
  metadata {
    name = "odc"
    labels = {
      project     = var.project
      environment = var.environment
      name        = local.odc_namespace
      managed-by  = "terraform"
    }
  }
}

# --- Create password for the ODC database connection ---
# --- Write password ---
resource "random_password" "odc_write" {
  length           = 32
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "odc_write_password" {
  name        = "${local.prefix}-odc-password"
  description = "Password for ODC database connection - Write"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "odc_write_password" {
  secret_id     = aws_secretsmanager_secret.odc_write_password.id
  secret_string = random_password.odc_write.result
}


# --- Read password ---
resource "random_password" "odc_read" {
  length           = 32
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "odc_read_password" {
  name        = "${local.prefix}-odc-read-password"
  description = "Password for ODC database connection - Read"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "odc_read_password" {
  secret_id     = aws_secretsmanager_secret.odc_read_password.id
  secret_string = random_password.odc_read.result
}

# --- Pass ODC read secret to the odc namespace ---
# Only need the DB read secret in the ODC namespace. Writing is done in Argo.
resource "kubernetes_secret" "odcread_namespace_secret" {
  metadata {
    name      = "odcread-secret"
    namespace = kubernetes_namespace.odc.metadata[0].name
  }
  data = {
    username = "odcread"
    password = aws_secretsmanager_secret_version.odc_read_password.secret_string
  }
  type = "Opaque"
}

# --- Read-only IAM Policy ---
resource "aws_iam_policy" "read_policy" {
  name        = "svc-${local.service_account_name}-read-policy"
  description = "Read-only policy for S3 buckets for ${local.service_account_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectAcl",
        ]
        Effect = "Allow"
        Resource = flatten([
          for bucket in local.read_buckets : [
            "arn:aws:s3:::${bucket}",
            "arn:aws:s3:::${bucket}/*"
          ]
        ])
      }
    ]
  })
}

# --- IAM Role for Service Account (IRSA) ----
module "iam_eks_role_bucket" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "svc-${local.service_account_name}"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.odc.metadata[0].name}:${local.service_account_name}"]
    }
  }

  role_policy_arns = {
    ReadPolicy = aws_iam_policy.read_policy.arn
  }
}

# --- Set up a cloudfront cache for the `ows` endpoint ---
# --- Create Role to assume the cross-account role in the shared account ---
resource "aws_iam_role" "odc_cloudfront_role" {
  name = "odc-cloudfront-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::<your-spoke-account-id>:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# --- Attach the policy to the role ---
resource "aws_iam_role_policy" "odc_cloudfront_assume_crossaccount" {
  role = aws_iam_role.odc_cloudfront_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = var.odc_cloudfront_crossaccount_role_arn
      }
    ]
  })
}

# Create a custom certificate
resource "aws_acm_certificate" "ows_cache" {
  provider          = aws.virginia
  domain_name       = "ows.${local.subdomain}"
  validation_method = "DNS"

  tags = merge(
    local.tags,
    {
      Purpose = "ows-cache"
    }
  )
}

# Validation of the certificate
resource "aws_route53_record" "ows_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.ows_cache.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.public_hosted_zone_id
}

resource "aws_acm_certificate_validation" "ows_certificate" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.ows_cache.arn
  validation_record_fqdns = [for record in aws_route53_record.ows_certificate : record.fqdn]
}

# Create a CloudFront distribution
resource "aws_cloudfront_distribution" "ows_cache" {
  depends_on = [aws_acm_certificate_validation.ows_certificate]
  origin {
    domain_name = "ows-uncached.${local.subdomain}"
    origin_id   = "owsOrigin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }

    # Here is the custom header definition
    custom_header {
      name  = "X-Public-Host"
      value = "ows.${local.subdomain}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""
  aliases = [
    "ows.${local.subdomain}"
  ]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "owsOrigin"

    forwarded_values {
      query_string = true
      headers = [
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
      ]
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.ows_cache.arn
    ssl_support_method  = "sni-only"
  }

  # Don't cache 500, 502, 503 or 504 errors
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 500
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 502
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 503
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 504
  }

  tags = merge(
    local.tags,
    {
      Name = "ows-cache"
    }
  )
}


# Set up DNS for the cloudfront distribution
resource "aws_route53_record" "ows_cache" {
  zone_id = var.public_hosted_zone_id
  name    = "ows"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ows_cache.domain_name
    zone_id                = aws_cloudfront_distribution.ows_cache.hosted_zone_id
    evaluate_target_health = false
  }
}
