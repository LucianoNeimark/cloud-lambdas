module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc.vpc_name
  cidr = var.vpc.vpc_cidr

  azs                  = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets      = [for subnet in var.vpc.subnets : subnet.cidr_block]
  private_subnet_names = [for subnet in var.vpc.subnets : subnet.name]

  tags = {
    Name = var.vpc.vpc_name
  }
}

resource "aws_security_group" "estacionamiento" {
  vpc_id = module.vpc.vpc_id
  name   = "estacionamiento"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
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

resource "aws_dynamodb_table" "users" {
  name     = "users"
  hash_key = "username"
  attribute {
    name = "username"
    type = "S"
  }
  read_capacity  = 1
  write_capacity = 1
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Name = "${var.vpc.vpc_name}-dynamodb-endpoint"
  }
}

module "lambdas" {
  source = "./modules/lambdas"
  lambdas_configs = [for lambda in var.lambda_configs : {
    name      = lambda.name
    handler   = lambda.handler
    runtime   = lambda.runtime
    filename  = lambda.filename
    role      = data.aws_iam_role.lab_role.arn
    variables = lambda.variables
  }]
  subnet_ids        = module.vpc.private_subnets
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
  user_pool_app_client_id = aws_cognito_user_pool_client.userpool_client.id
  user_pool_url           = format("%s%s", "https://", aws_cognito_user_pool.estacionamiento.endpoint)
}

resource "aws_lambda_function" "redirect" {
  function_name    = "redirectLambda"
  handler          = "redirectLambda.lambda_handler"
  runtime          = "python3.10"
  filename         = "../lambdas/redirectLambda.zip"
  source_code_hash = filebase64sha256("../lambdas/redirectLambda.zip")
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 30

  environment {
    variables = {
      "frontend_url" = aws_s3_bucket_website_configuration.estacionamiento_frontend.website_endpoint
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function_url" "redirect" {
  function_name      = aws_lambda_function.redirect.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

resource "aws_cognito_user_pool" "estacionamiento" {
  name = "estacionamiento"

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  auto_verified_attributes = ["email"]

  username_attributes = ["email"]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "estacionamiento-app-auth-3" # TODO add random string
  user_pool_id = aws_cognito_user_pool.estacionamiento.id
}

resource "aws_cognito_user_pool_client" "userpool_client" {
  name                                 = "estacionamiento-client"
  user_pool_id                         = aws_cognito_user_pool.estacionamiento.id
  callback_urls                        = [aws_lambda_function_url.redirect.function_url]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
}


resource "aws_cognito_user_group" "main" {
  name         = "estacionamiento-admin"
  user_pool_id = aws_cognito_user_pool.estacionamiento.id
}

resource "aws_lambda_function" "addUserToGroup" {
  function_name    = "addUserToGroup"
  handler          = "addUserToGroup.lambda_handler"
  runtime          = "python3.10"
  filename         = "../lambdas/addUserToGroup.zip"
  source_code_hash = filebase64sha256("../lambdas/addUserToGroup.zip")
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 30

  environment {
    variables = {
      "user_pool_id" = aws_cognito_user_pool.estacionamiento.id
    }
  }

  tracing_config {
    mode = "Active"
  }
}
