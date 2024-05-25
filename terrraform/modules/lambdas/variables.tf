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

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}
