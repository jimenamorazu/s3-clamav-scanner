## ECR
module "ecr" {
  source          = "terraform-aws-modules/ecr/aws"
  repository_name = var.ecr_repo_name
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  repository_lambda_read_access_arns = [
    module.lambda_function.lambda_function_arn
  ]
  repository_image_tag_mutability = "MUTABLE"
}

## EFS

resource "aws_efs_file_system" "efs_for_lambda" {
  tags = {
    Name = var.name
  }
  encrypted = true
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
}

resource "aws_efs_mount_target" "mount" {
  for_each        = toset(data.aws_subnets.private.ids)
  file_system_id  = aws_efs_file_system.efs_for_lambda.id
  subnet_id       = each.value
  security_groups = [module.efs_sg.security_group_id]
}

resource "aws_efs_access_point" "access_point_for_lambda" {
  file_system_id = aws_efs_file_system.efs_for_lambda.id
  tags = {
    Name = var.name
  }

  root_directory {
    path = "/lambda"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  posix_user {
    gid            = 1000
    uid            = 1000
    secondary_gids = []
  }
}

module "efs_sg" {
  version = "5.1.0"
  source  = "terraform-aws-modules/security-group/aws"

  name        = "nfs-${var.name}-${var.environment}"
  description = "Security group for ${var.name} NFS"
  vpc_id      = var.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 86
      to_port     = 86
      protocol    = "252"
      description = "Disallow outbound traffic"
      cidr_blocks = "255.255.255.255/32"
    },

  ]

  ingress_with_source_security_group_id = [
    {
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      description              = "Allow access from Lambda"
      source_security_group_id = module.lambda_function.security_group_id
    },
  ]
}

## Lambda Function
module "lambda_function" {
  source               = "../../modules/lambda"
  environment          = var.environment
  lambda_name          = var.name
  lambda_env_variables = merge(local.lambda_env_variables, var.lambda_env_variables)
  timeout              = var.timeout
  vpc_id               = var.vpc_id
  ecr_repo_arn         = module.ecr.repository_arn
  image_tag            = var.lambda_image_tag
  ecr_repo_url         = module.ecr.repository_url
  lambda_policy_json   = [data.aws_iam_policy_document.lambda.json]
  lambda_memory        = var.lambda_memory
  file_system_config = [
    {
      arn              = aws_efs_access_point.access_point_for_lambda.arn
      local_mount_path = local.lambda_mount_path
    }
  ]
  depends_on = [aws_efs_mount_target.mount]
}

resource "aws_security_group_rule" "nfs" {
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Outbound access to NFS"
  source_security_group_id = module.efs_sg.security_group_id
  type                     = "egress"
  security_group_id        = module.lambda_function.security_group_id
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "s3:GetBucket*",
      "s3:GetObject*",
      "s3:List*"
    ]
    resources = [
      data.aws_s3_bucket.definitions_bucket.arn,
      "${data.aws_s3_bucket.definitions_bucket.arn}/*",
      module.file_upload_s3_bucket.s3_bucket_arn,
      "${module.file_upload_s3_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging"
    ]
    resources = [
      "${module.file_upload_s3_bucket.s3_bucket_arn}/*"
    ]
  }
  statement {
    actions = [
      "elasticfilesystem:ClientMount"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [aws_efs_access_point.access_point_for_lambda.arn]
    }
  }
}

## S3
module "logging_s3_bucket" {
  source                                     = "terraform-aws-modules/s3-bucket/aws"
  version                                    = "3.14.1"
  bucket                                     = local.logging_bucket_name
  access_log_delivery_policy_source_accounts = [data.aws_caller_identity.current.account_id]
  access_log_delivery_policy_source_buckets = [
    module.file_upload_s3_bucket.s3_bucket_arn
  ]
  attach_access_log_delivery_policy     = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
}

module "file_upload_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.1"
  bucket  = local.bucket_name
  logging = {
    target_bucket = local.logging_bucket_name
    target_prefix = local.bucket_name
  }
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
}

module "lambda_notification" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "3.14.1"

  bucket = module.file_upload_s3_bucket.s3_bucket_id

  lambda_notifications = {
    lambda = {
      function_arn  = module.lambda_function.lambda_function_arn
      function_name = module.lambda_function.lambda_function_name
      events        = ["s3:ObjectCreated:*"]
    }
  }
}
