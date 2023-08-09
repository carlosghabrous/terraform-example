variable "region" {
  description = "Deployment region"
  type        = string
  default     = "eu-central-1"
}

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
}

variable "instance_type" {
  description = "EC2 instances instance type"
  type        = string
  default     = "t2.micro"
}

variable "bucket_name" {
  description = "Application's S3 bucket name"
  type        = string
  default     = "ghab-tf-course-state"
}

variable "domain" {
  description = "The app's domain"
  type        = string

}

variable "db_name" {
  description = "DB name"
  type        = string
}

variable "db_user" {
  description = "The DB user"
  type        = string
}

variable "db_password" {
  description = "The password"
  type        = string
  sensitive   = true
}

variable "bucket_prefix" {
  description = "prefix of s3 bucket for app data"
  type        = string
}