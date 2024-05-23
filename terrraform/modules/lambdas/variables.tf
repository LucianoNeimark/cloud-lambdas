variable "lambdas_configs" {
  type = list(object({
    name      = string
    handler   = string
    runtime   = string
    filename  = string
    role      = string
    variables = map(string)
  }))
}
