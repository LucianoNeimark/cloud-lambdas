resource "aws_lambda_function" "this" {
  for_each         = { for lambda in var.lambdas_configs : lambda.name => lambda }
  function_name    = each.value.name
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = each.value.filename
  source_code_hash = filebase64sha256(each.value.filename)
  role             = each.value.role
  timeout          = 30
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  environment {
    variables = each.value.variables
  }

  tracing_config {
    mode = "Active"
  }
}

