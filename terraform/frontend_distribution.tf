
resource "aws_s3_bucket" "estacionamiento_frontend" {
  bucket_prefix = "estacionamiento-frontend"
}

resource "aws_s3_bucket_public_access_block" "estacionamiento_frontend" {
  bucket                  = aws_s3_bucket.estacionamiento_frontend.bucket
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "estacionamiento_frontend" {
  bucket = aws_s3_bucket.estacionamiento_frontend.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.estacionamiento_frontend.arn}/*"
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
        Action   = "s3:PutObject"
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
