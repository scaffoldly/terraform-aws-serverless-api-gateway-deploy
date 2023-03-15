variable "repository_name" {
  type = string
}

variable "source_directory" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "runtime" {
  type = string
}

variable "handler" {
  type    = string
  default = "lambda.handler"
}

variable "role" {
  type = string
}

variable "api_id" {
  type = string
}

variable "root_resource_id" {
  type = string
}