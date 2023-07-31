locals {
  publish                   = var.lambda_at_edge ? true : var.publish
  timeout                   = var.lambda_at_edge ? min(var.timeout, 5) : var.timeout
  lambda_log_group_arn      = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_name}_${var.environment}"
  lambda_edge_log_group_arn = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/us-east-1.${var.lambda_name}_${var.environment}"
  log_group_arns            = slice([local.lambda_log_group_arn, local.lambda_edge_log_group_arn], 0, var.lambda_at_edge ? 2 : 1)
  image_tag                 = var.ecr_repo_arn != null && var.image_tag == null ? var.environment : var.image_tag
  image_uri                 = "${var.ecr_repo_url}:${local.image_tag}"
  package_type              = var.ecr_repo_arn != null ? "Image" : "Zip"
  iam_name                  = "${var.lambda_name}-${var.environment}-${data.aws_region.current.name}"
}

#Data Sources
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_subnets" "private" {
  count = var.vpc_id == null ? 0 : 1
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Tier"
    values = ["private", "Private"]
  }
}

resource "aws_lambda_function" "lambda_function" {
  function_name                  = var.lambda_name
  handler                        = var.lambda_handler
  role                           = aws_iam_role.lambda_role.arn
  runtime                        = var.lambda_runtime
  timeout                        = local.timeout
  memory_size                    = var.lambda_memory
  publish                        = local.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  tags                           = var.lambda_tags
  layers                         = var.lambda_layers
  package_type                   = local.package_type

  #Set if S3 bucket and key are used as lambda's source
  s3_bucket = var.lambda_bucket_name
  s3_key    = var.code_key

  #Set if source_path and filename are used as lambda's source
  filename         = var.lambda_source_path != null ? data.archive_file.source_file[0].output_path : null
  source_code_hash = var.lambda_source_path != null ? data.archive_file.source_file[0].output_base64sha256 : null

  #Set if ECR image URI is used as lambda's source
  image_uri = local.image_uri

  dynamic "environment" {
    for_each = var.lambda_env_variables == null ? [] : [var.lambda_env_variables]
    content {
      variables = var.lambda_env_variables
    }
  }
  dynamic "vpc_config" {
    for_each = var.vpc_id == null ? [] : toset([var.vpc_id])
    content {
      security_group_ids = [module.lambda_sg[0].security_group_id]
      subnet_ids         = data.aws_subnets.private[0].ids
    }
  }

  dynamic "file_system_config" {
    for_each = var.file_system_config == null ? [] : var.file_system_config
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

}

data "archive_file" "source_file" {
  count       = var.lambda_source_path == null ? 0 : 1
  type        = "zip"
  source_dir  = var.lambda_source_path
  output_path = "${path.module}/${var.lambda_name}.zip"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}_${var.environment}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_at_edge_log_group" {
  count             = var.lambda_at_edge ? 1 : 0
  name              = "/aws/lambda/us-east-1.${var.lambda_name}_${var.environment}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_policy" {
  override_policy_documents = var.lambda_policy_json

  statement {
    sid    = "CloudWatchLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = concat(formatlist("%v:", local.log_group_arns), formatlist("%v::*", local.log_group_arns))
  }
  dynamic "statement" {
    for_each = var.ecr_repo_arn != null ? [var.ecr_repo_arn] : []
    content {
      sid    = "ECRImageAccess"
      effect = "Allow"
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
      ]
      resources = [
        var.ecr_repo_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.ecr_repo_arn != null ? [var.ecr_repo_arn] : []
    content {
      sid    = "ECRAuthToken"
      effect = "Allow"
      actions = [
        "ecr:GetAuthorizationToken"
      ]
      resources = ["*"]
    }
  }
}

# Security Groups
module "lambda_sg" {
  count   = var.vpc_id != null ? 1 : 0
  version = "5.1.0"
  source  = "terraform-aws-modules/security-group/aws"

  name        = "${var.lambda_name}-lambda-sg-${var.environment}"
  description = "Security group for ${var.lambda_name} lambda VPC access"
  vpc_id      = var.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "External access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

}


resource "aws_iam_policy" "lambda_policy" {
  name        = local.iam_name
  description = "Policy specified for the specific function of the ${var.lambda_name} lambda."
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

data "aws_iam_policy_document" "LambdaAssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = local.iam_name
  assume_role_policy = data.aws_iam_policy_document.LambdaAssumeRolePolicy.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.id
}

resource "aws_iam_role_policy_attachment" "basic_lambda_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_role.id
}