terraform {

  backend "s3" {
    bucket         = "ghab-tf-course-state"
    key            = "tf-infra/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "ghab_tf_course_state" {
  bucket        = "ghab-tf-course-state"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.ghab_tf_course_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_enc_configuration" {
  bucket = aws_s3_bucket.ghab_tf_course_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}