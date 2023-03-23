variable "repository_name" {
  type = string
}

variable "dist_dir" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "runtime" {
  type = string
}

variable "handler" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "api_id" {
  type = string
}

variable "root_resource_id" {
  type = string
}

variable "api_path" {
  type = string
}

variable "create_archive" {
  type    = bool
  default = true
}
