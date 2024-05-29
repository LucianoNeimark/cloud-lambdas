
resource "aws_s3_bucket" "estacionamiento_frontend" {
  bucket_prefix = "estacionamiento-frontend"
}

resource "aws_s3_bucket_public_access_block" "estacionamiento_frontend" {
  bucket                  = aws_s3_bucket.estacionamiento_frontend.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "estacionamiento_frontend" {
  bucket = aws_s3_bucket.estacionamiento_frontend.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "estacionamiento_frontend" {
  bucket = aws_s3_bucket.estacionamiento_frontend.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.estacionamiento_frontend,
    aws_s3_bucket_public_access_block.estacionamiento_frontend,
  ]

  bucket = aws_s3_bucket.estacionamiento_frontend.bucket
  acl    = "private"
}


resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.estacionamiento_frontend.bucket_regional_domain_name
    origin_id   = "s3-my-private-static-website"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-my-private-static-website"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
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
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "OAI for my-private-static-website"
}

resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = aws_s3_bucket.estacionamiento_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.estacionamiento_frontend.arn}/*"
      }
    ]
  })
}


resource "aws_s3_bucket" "log_bucket" {
  bucket_prefix = "estacionamiento-log"
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_logging" "example" {
  bucket        = aws_s3_bucket.estacionamiento_frontend.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}