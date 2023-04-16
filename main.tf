data "aws_lambda_function" "function" {
  function_name = var.function_name
  qualifier     = var.function_version
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
  uri                     = data.aws_lambda_function.function.qualified_invoke_arn
}

resource "aws_api_gateway_integration" "base_proxy" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.base_proxy.id
  http_method             = aws_api_gateway_method.base_proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = data.aws_lambda_function.function.qualified_invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = var.api_id

  triggers = {
    redeployment = data.aws_lambda_function.function.source_code_hash
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_resource.base,
    aws_api_gateway_integration.base_proxy
  ]
}