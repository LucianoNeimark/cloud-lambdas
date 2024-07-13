resource "null_resource" "build_with_gateway_endpoint" {
  provisioner "local-exec" {
    command = <<EOF
    docker build -t estacionamiento-frontend-builder --build-arg REACT_APP_API_URL=${module.api-gateway-lambdas.stage_url} ../frontend/estacionamiento
    docker run --name estacionamiento-frontend-builder-container estacionamiento-frontend-builder
    docker cp estacionamiento-frontend-builder-container:/app/build ../frontend/estacionamiento
    docker rm estacionamiento-frontend-builder-container
    
    # TODO use aws sync instead of cp
    EOF
  }
  triggers = {
    build_path = "${module.api-gateway-lambdas.stage_url}"
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
