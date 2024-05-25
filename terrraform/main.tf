module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc.vpc_cidr
  vpc_name           = var.vpc.vpc_name
  subnets            = var.vpc.subnets
  availability_zones = slice(data.aws_availability_zones.available, 0, 2)
}

resource "aws_security_group" "estacionamiento" {
  vpc_id = module.vpc.vpc_id
  name   = "estacionamiento"
}

# DynamoDB table
resource "aws_dynamodb_table" "estacionamiento" {
  name      = "estacionamiento"
  hash_key  = "region"
  range_key = "id"
  attribute {
    name = "region"
    type = "S"
  }
  attribute {
    name = "id"
    type = "S"
  }
  read_capacity  = 1
  write_capacity = 1
}

# TODO pass role as param
module "lambdas" {
  source            = "./modules/lambdas"
  lambdas_configs   = var.lambda_configs
  subnet_ids        = module.vpc.subnet_ids
  security_group_id = aws_security_group.estacionamiento.id
}

module "api-gateway-lambdas" {
  source = "./modules/api-gateway-lambdas"
  api_gateway_config = {
    name        = "estacionamiento-api"
    description = "API for estacionamiento"
  }
  api_gateway_endpoints_configs = [for endpoint in var.api_endpoints : {
    name        = endpoint.name
    path        = endpoint.path
    method      = endpoint.method
    lambda_arn  = module.lambdas.created_lambdas[endpoint.lambda_name].invoke_arn
    lambda_name = module.lambdas.created_lambdas[endpoint.lambda_name].function_name
  }]
}

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

# TODO preguntar sobre esto, si hay una forma mejor / si esto es muy feo
resource "null_resource" "modify_file_and_build" {
  provisioner "local-exec" {
    command = <<EOF
    echo REACT_APP_API_URL=${module.api-gateway-lambdas.stage_url} > ./frontend/estacionamiento/.env
    cd ./frontend/estacionamiento
    npm install
    npm run build
    EOF
  }
  triggers = {
    build_path = "./frontend/estacionamiento/build"
  }
}
resource "aws_s3_object" "object" {
  depends_on   = [null_resource.modify_file_and_build]
  for_each     = fileset("./frontend/estacionamiento/build", "**/*")
  bucket       = aws_s3_bucket.estacionamiento_frontend.bucket
  key          = each.value
  source       = "./frontend/estacionamiento/build/${each.value}"
  etag         = filemd5("./frontend/estacionamiento/build/${each.value}")
  content_type = lookup(local.content_types, lower(element(split(".", each.value), length(split(".", each.value)) - 1)), "binary/octet-stream")
  # FIXME this will not work when the files are changed for another motive
  lifecycle {
    ignore_changes = [etag]
  }
}
