# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "project_name" {
  type        = string
  description = "Name of this project."

  default     = "dynamic-aws-creds-vault"
}

variable "region" {
  type        = string
  description = "AWS region for all resources."

  default = "ap-southeast-2"
}

variable "aws_access_key" {
  type        = string
  description = "access key."
}

variable "aws_secret_key" {
  type        = string
  description = "secret key."
}
