resource "null_resource" "build_with_gateway_endpoint" {
  provisioner "local-exec" {
    command = <<EOF
    docker build -t estacionamiento-frontend-builder \
    --build-arg REACT_APP_API_URL=${module.api-gateway-lambdas.stage_url} \
    --build-arg REACT_APP_CLIENT_ID='${aws_cognito_user_pool_client.userpool_client.id}' \
    --build-arg REACT_APP_COGNITO_URL='${terraform_data.cognito_base_url.output}' \
    --build-arg REACT_APP_REDIRECT_URL='${aws_lambda_function_url.redirect.function_url}' \
    ../frontend/estacionamiento    
    docker run --name estacionamiento-frontend-builder-container estacionamiento-frontend-builder
    docker cp estacionamiento-frontend-builder-container:/app/build ../frontend/estacionamiento
    docker rm estacionamiento-frontend-builder-container
    
    # TODO use aws sync instead of cp
    EOF
  }
  triggers = {
    build_path  = "${module.api-gateway-lambdas.stage_url}"
    login_url   = terraform_data.cognito_hosted_ui_url.output
    code_change = md5(join("", [for v in fileset("../frontend/estacionamiento/src", "**/**") : filemd5("../frontend/estacionamiento/src/${v}")]))
    test        = "b"
  }
}

resource "aws_s3_object" "object" {
  depends_on   = [null_resource.build_with_gateway_endpoint, aws_s3_bucket.estacionamiento_frontend]
  for_each     = fileset("../frontend/estacionamiento/build", "**/*")
  bucket       = aws_s3_bucket.estacionamiento_frontend.bucket
  key          = each.value
  source       = "../frontend/estacionamiento/build/${each.value}"
  etag         = filemd5("../frontend/estacionamiento/build/${each.value}")
  content_type = lookup(local.content_types, lower(element(split(".", each.value), length(split(".", each.value)) - 1)), "binary/octet-stream")
  lifecycle {
    create_before_destroy = true
  }
}

