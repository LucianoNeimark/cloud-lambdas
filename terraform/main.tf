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
  lambdas_configs = concat([for lambda in var.lambda_configs : {
    name      = lambda.name
    handler   = lambda.handler
    runtime   = lambda.runtime
    filename  = lambda.filename
    role      = data.aws_iam_role.lab_role.arn
    variables = lambda.variables
    }],
    [{
      name     = "redirectLambda"
      handler  = "redirectLambda.lambda_handler"
      runtime  = "python3.10"
      filename = "../lambdas/redirectLambda.zip"
      role     = data.aws_iam_role.lab_role.arn
      variables = {
        "frontend_url" = aws_s3_bucket_website_configuration.estacionamiento_frontend.website_endpoint
      } }
    ]
  )
  subnet_ids        = module.vpc.private_subnets
  security_group_id = aws_security_group.estacionamiento.id
}

resource "aws_lambda_function" "post-register" {
  function_name    = "postRegister"
  handler          = "postRegister.lambda_handler"
  runtime          = "python3.10"
  filename         = "../lambdas/postRegister.zip"
  source_code_hash = filebase64sha256("../lambdas/postRegister.zip")
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 30
  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.estacionamiento.id]
  }

  environment {
    variables = {
      user_table = "users"
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function" "become-admin" {
  function_name    = "addUserToGroup"
  handler          = "addUserToGroup.lambda_handler"
  runtime          = "python3.10"
  filename         = "../lambdas/addUserToGroup.zip"
  source_code_hash = filebase64sha256("../lambdas/addUserToGroup.zip")
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 30

  environment {
    variables = {
      user_pool_id = aws_cognito_user_pool.estacionamiento.id
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cognito_to_invoke" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post-register.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.estacionamiento.arn
}

module "api-gateway-lambdas" {
  source = "./modules/api-gateway-lambdas"
  api_gateway_config = {
    name        = "estacionamiento-api"
    description = "API for estacionamiento"
  }
  api_gateway_endpoints_configs = concat([for endpoint in var.api_endpoints : {
    name                 = endpoint.name
    path                 = endpoint.path
    method               = endpoint.method
    lambda_arn           = module.lambdas.created_lambdas[endpoint.lambda_name].invoke_arn
    lambda_name          = module.lambdas.created_lambdas[endpoint.lambda_name].function_name
    authorization_scopes = endpoint.authorization_scopes
    }], [{
    name                 = "addUserToAdmin"
    path                 = "/become-admin"
    method               = "POST"
    lambda_arn           = aws_lambda_function.become-admin.invoke_arn
    lambda_name          = aws_lambda_function.become-admin.function_name
    authorization_scopes = []
  }])
  user_pool_app_client_id = aws_cognito_user_pool_client.userpool_client.id
  user_pool_url           = format("%s%s", "https://", aws_cognito_user_pool.estacionamiento.endpoint)
}

resource "aws_lambda_function_url" "redirect" {
  function_name      = module.lambdas.created_lambdas["redirectLambda"].function_name
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

  lambda_config {
    post_confirmation = aws_lambda_function.post-register.arn
  }
}

resource "random_id" "random" {
  byte_length = 8
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "estacionamiento-app-auth-${random_id.random.hex}"
  user_pool_id = aws_cognito_user_pool.estacionamiento.id
}

resource "aws_cognito_user_pool_client" "userpool_client" {
  name                                 = "estacionamiento-client"
  user_pool_id                         = aws_cognito_user_pool.estacionamiento.id
  callback_urls                        = [aws_lambda_function_url.redirect.function_url]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30
}

resource "aws_cognito_user_group" "main" {
  name         = "estacionamiento-admin"
  user_pool_id = aws_cognito_user_pool.estacionamiento.id
}

resource "terraform_data" "cognito_hosted_ui_url" {
  input = "${terraform_data.cognito_base_url.output}login?response_type=code&client_id=${aws_cognito_user_pool_client.userpool_client.id}&redirect_uri=${aws_lambda_function_url.redirect.function_url}"
  triggers_replace = [
    aws_cognito_user_pool.estacionamiento.endpoint,
    aws_cognito_user_pool_client.userpool_client.id,
    aws_lambda_function_url.redirect.function_url
  ]
}

resource "terraform_data" "cognito_base_url" {
  input = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/"
  triggers_replace = [
    aws_cognito_user_pool_domain.main.domain,
    data.aws_region.current.name
  ]
}
