data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Tier"
    values = ["private", "Private"]
  }
}

data "aws_s3_bucket" "definitions_bucket" {
  bucket = var.definitions_bucket_id
}

data "aws_caller_identity" "current" {}
