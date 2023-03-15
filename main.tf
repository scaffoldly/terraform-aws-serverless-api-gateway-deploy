locals {
  function_name = "${var.repository_name}-${var.api_path}"
  archive_name  = "${var.repository_name}-${var.api_path}.zip"
  api_parts     = split("/", var.api_path)
  last_part     = length(local.api_parts) - 1
}

resource "aws_s3_object" "archive" {
  bucket = var.bucket_name

  key    = "dist/${local.archive_name}"
  source = var.dist_zip

  etag = filemd5(var.dist_zip)
}

resource "aws_lambda_function" "function" {
  function_name = local.function_name

  s3_bucket = aws_s3_object.archive.bucket
  s3_key    = aws_s3_object.archive.key

  runtime = var.runtime
  handler = var.handler

  source_code_hash = filebase64sha256(var.dist_zip)

  role = var.role_arn
}

resource "aws_api_gateway_resource" "base" {
  count       = length(local.api_parts)
  rest_api_id = var.api_id
  parent_id   = count.index == 0 ? var.root_resource_id : aws_api_gateway_resource.base[count.index - 1].id
  path_part   = local.api_parts[count.index]
}

resource "aws_api_gateway_resource" "base_proxy" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.base[local.last_part].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "base" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.base[local.last_part].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "base_proxy" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.base_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "base" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.base[local.last_part].id
  http_method             = aws_api_gateway_method.base.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_integration" "base_proxy" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.base_proxy.id
  http_method             = aws_api_gateway_method.base_proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = var.api_id

  triggers = {
    redeployment = aws_lambda_function.function.source_code_hash
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.base,
    aws_api_gateway_integration.base_proxy
  ]
}