variable "lambda_configs" {
  type = list(object({
    name      = string
    handler   = string
    runtime   = string
    filename  = string
    variables = map(string)
  }))
}

variable "api_endpoints" {
  type = list(object({
    name                 = string
    method               = string
    path                 = string
    lambda_name          = string
    authorization_scopes = list(string)
  }))
}

variable "vpc" {
  type = object({
    vpc_cidr = string
    vpc_name = string
    subnets = list(object({
      name       = string
      cidr_block = string
    }))
    public_subnets = list(object({
      name       = string
      cidr_block = string
    }))
  })
}
