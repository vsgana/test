terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
  region=var.region
}

resource "aws_security_group" "seg_as" {
  name = "stg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "TF_key" {
  key_name   = "assisment"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "TF_key" {
  content  = tls_private_key.rsa.private_key_openssh
  filename = "assisment"
}
resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-ec2-logs-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 7
    }
    filter {}
  }
}

resource "aws_instance" "aws_dev" {
  ami = var.ami_id
  instance_type = var.instance_type
  depends_on = [aws_security_group.seg_as,
     aws_iam_instance_profile.ec2_profile,
     aws_s3_bucket.logs
  ]
  key_name = aws_key_pair.TF_key.key_name
  iam_instance_profile =aws_iam_instance_profile.ec2_profile.name
  tags = {
     Name = "web-${var.stage}"
     Stage = var.stage
  }
  user_data = templatefile("${path.module}/scripts/scripts.sh", {
   bucket_name = aws_s3_bucket.log_bucket.bucket
})
}
resource "aws_instance" "reader_instance" {
  ami                    = "ami-0d03cb826412c6b0f"
  key_name = aws_key_pair.TF_key.key_name
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.reader_profile.name
  security_groups        = [aws_security_group.ec2_sg.name]
  tags = {
    Name = "Reader-EC2"
  }
}