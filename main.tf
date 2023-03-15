locals {
  function_name = "${var.repository_name}-${var.api_path}"
  archive_name  = "${var.repository_name}-${var.api_path}.zip"
}

data "archive_file" "archive" {
  type = "zip"

  source_dir  = var.dist_dir
  output_path = "${path.module}/${local.archive_name}"
}

resource "aws_s3_object" "archive" {
  bucket = var.bucket_name

  key    = "dist/${local.archive_name}"
  source = data.archive_file.archive.output_path

  etag = filemd5(data.archive_file.archive.output_path)
}

resource "aws_lambda_function" "function" {
  function_name = local.function_name

  s3_bucket = aws_s3_object.archive.bucket
  s3_key    = aws_s3_object.archive.key

  runtime = var.runtime
  handler = var.handler

  source_code_hash = data.archive_file.archive.output_base64sha256

  role = var.role
}

resource "aws_api_gateway_resource" "base" {
  rest_api_id = var.api_id
  parent_id   = var.root_resource_id
  path_part   = var.api_path
}

resource "aws_api_gateway_resource" "base_proxy" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.base.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "base" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.base.id
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
  resource_id             = aws_api_gateway_resource.base.id
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