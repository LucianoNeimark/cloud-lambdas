data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_lambda_function" "this" {
  for_each         = { for lambda in var.lambdas_configs : lambda.name => lambda }
  function_name    = each.value.name
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = each.value.filename
  source_code_hash = filebase64sha256(each.value.filename)
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 30

  environment {
    variables = each.value.variables
  }

  tracing_config {
    mode = "Active"
  }
}

