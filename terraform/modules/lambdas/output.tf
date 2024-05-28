output "created_lambdas" {
  value = {
    for lambda in var.lambdas_configs : lambda.name => aws_lambda_function.this[lambda.name]
  }
}
