output "api_base_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "api_path" {
  value = var.api_path
}

output "api_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/${var.api_path}"
}
