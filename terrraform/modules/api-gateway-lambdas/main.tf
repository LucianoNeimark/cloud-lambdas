resource "aws_apigatewayv2_api" "estacionamiento" {
  name          = var.api_gateway_config.name
  description   = var.api_gateway_config.description
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "estacionamiento" {
  for_each           = { for endpoint in var.api_gateway_endpoints_configs : endpoint.lambda_name => endpoint }
  api_id             = aws_apigatewayv2_api.estacionamiento.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = each.value.lambda_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = { for endpoint in var.api_gateway_endpoints_configs : endpoint.lambda_name => endpoint }
  statement_id  = each.value.lambda_name
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.estacionamiento.execution_arn}/*/*/*"
}

resource "aws_apigatewayv2_route" "estacionamiento" {
  for_each  = { for endpoint in var.api_gateway_endpoints_configs : endpoint.name => endpoint }
  api_id    = aws_apigatewayv2_api.estacionamiento.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.estacionamiento[each.value.lambda_name].id}"
}

resource "aws_apigatewayv2_stage" "estacionamiento" {
  api_id      = aws_apigatewayv2_api.estacionamiento.id
  name        = "dev"
  auto_deploy = true
  lifecycle {
    create_before_destroy = true
  }
}
