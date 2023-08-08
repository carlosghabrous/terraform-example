terraform {

  backend "s3" {
    bucket         = "ghab-tf-course-state"
    key            = "web-app/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "harshicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "instance_1" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
  #!/bin/bash
  echo "Hello, World 1" > index.html
  python3 -m http.server 8080 &
  EOF
}

resource "aws_instance" "instance_2" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
  #!/bin/bash
  echo "Hello, World 2" > index.html
  python3 -m http.server 8080 &
  EOF
}

resource "aws_s3_bucket" "instances_bucket" {
  bucket = "instances-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "instances_bucket_ver" {
  bucket = aws_s3_bucket.instances_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_enc_configuration" {
  bucket = aws_s3_bucket.instances_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# to allow inbound traffic 
resource "aws_security_group" "instances" {
  name = "instance-security-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.instances.id

    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cird_blocks = ["0.0.0.0/0"]
}

// load balancer
resource "aws_alb_listener" "http" {
    load_balancer_arn = aws_lb.load_balancer.load_balancer_arn

    port = 80
    protocol = "HTTP"

    default_action {
        type = "fixed-response"
    }

    fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code = 404
    }
}

resource "aws_lb_target_group" "instances" {
  name = "example-target-group"
  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.default_vpc.id

  healthcheck {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id = aws_instance.instance_1.id
  port = 8080

}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id = aws_instance.instance_2.id
  port = 8080

}



