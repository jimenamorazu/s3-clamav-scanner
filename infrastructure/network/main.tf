locals {
  availability_zones          = length(var.availability_zones) > 0 ? var.availability_zones : ["${var.region}a", "${var.region}c"]
  private_subnets_cidr_blocks = length(var.private_subnets_cidr_blocks) > 0 ? var.private_subnets_cidr_blocks : [cidrsubnet(var.cidr_block, 8, 1), cidrsubnet(var.cidr_block, 8, 2)]
  public_subnets_cidr_blocks  = length(var.public_subnets_cidr_blocks) > 0 ? var.public_subnets_cidr_blocks : [cidrsubnet(var.cidr_block, 8, 100), cidrsubnet(var.cidr_block, 8, 101)]
  log_prefix                  = "${var.environment}/logs"
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = var.environment
  cidr = var.cidr_block

  azs             = local.availability_zones
  private_subnets = local.private_subnets_cidr_blocks
  private_subnet_tags = {
    Tier = "Private"
  }
}

# Logs for VPC
resource "aws_flow_log" "flow_logs" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name = "${var.environment}-flow-logs"
}

resource "aws_iam_role" "flow_logs" {
  name               = "${var.environment}-alb-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume.json
}

data "aws_iam_policy_document" "flow_logs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "flow-logs" {
  name   = "${var.environment}-flow-logs"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs.json
}

data "aws_iam_policy_document" "flow_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  vpc_id            = module.vpc.vpc_id
  route_table_ids   = module.vpc.private_route_table_ids
}

