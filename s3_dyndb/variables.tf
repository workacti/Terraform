variable "project_name" {
  type        = string
  description = "Name of the example project."

  default     = "dynamic-aws-creds-operator"
}

variable "region" {
  type        = string
  description = "AWS region for all resources."

  default = "ap-southeast-2"
}

variable "vault_state_path" {
  type        = string
  description = "Path to state file of vault admin workspace."

  default     = "../vault-admin-workspace/terraform.tfstate"
}

variable "ttl" {
  type        = string
  description = "Value for TTL tag."

  default     = "1"
}
