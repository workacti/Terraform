provider "aws" {
  region     = "${var.region}"
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
}

provider "vault" {}

data "terraform_remote_state" "admin" {
  backend = "local"
  config = {
    path = var.vault_state_path
  }
}

data "vault_aws_access_credentials" "creds" {
  backend = data.terraform_remote_state.admin.outputs.backend
  role    = data.terraform_remote_state.admin.outputs.role
}

#resource "aws_dynamodb_table" "terraform_locks" {
#  name         = "sbs-test-dynamodb-table"
#  billing_mode = "PAY_PER_REQUEST"
#  hash_key     = "LockID"
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}

resource "aws_s3_bucket" "terraform-state" {
 bucket = "tf-state-s3rx"
 acl    = "private"

 versioning {
   enabled = true
 }

# server_side_encryption_configuration {
#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.terraform-bucket-key.arn
#       sse_algorithm     = "aws:kms"
#     }
#   }
# }
}

resource "aws_s3_bucket_public_access_block" "block" {
 bucket = aws_s3_bucket.terraform-state.id

 block_public_acls       = true
 block_public_policy     = true
 ignore_public_acls      = true
 restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform-state" {
 name           = "tf-state-dyndb"
 read_capacity  = 20
 write_capacity = 20
 hash_key       = "LockID"

 attribute {
   name = "LockID"
   type = "S"
 }
}
