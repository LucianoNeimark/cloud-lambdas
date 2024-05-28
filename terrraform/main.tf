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

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [module.vpc.private_route_table_id]

  tags = {
    Name = "${var.vpc.vpc_name}-dynamodb-endpoint"
  }
}

module "lambdas" {
  source            = "./modules/lambdas"
  lambdas_configs   = var.lambda_configs
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
}
