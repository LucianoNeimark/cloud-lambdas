variable "lambda_configs" {
  type = list(object({
    name      = string
    handler   = string
    runtime   = string
    filename  = string
    role      = string
    variables = map(string)
  }))
}

variable "api_endpoints" {
  type = list(object({
    name        = string
    method      = string
    path        = string
    lambda_name = string
  }))
}
