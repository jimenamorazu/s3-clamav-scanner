## ECR
module "ecr" {
  source          = "terraform-aws-modules/ecr/aws"
  repository_name = var.ecr_repo_name
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images with 'v' tag, remove others after 7 days",
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

## Lammbda Function
module "lambda_function" {
  source               = "../../modules/lambda"
  environment          = var.environment
  lambda_name          = var.name
  lambda_env_variables = merge(local.lambda_env_variables, var.lambda_env_variables)
  timeout              = var.timeout
  ecr_repo_arn         = module.ecr.repository_arn
  ecr_repo_url         = module.ecr.repository_url
  lambda_policy_json   = [data.aws_iam_policy_document.lambda.json]
  lambda_memory        = var.lambda_memory
  image_tag            = var.lambda_image_tag
}

## S3
module "clamav_defs_bucket" {
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "3.14.1"
  bucket                                = local.bucket_name
  attach_deny_insecure_transport_policy = true
}

## Uploads initial config into bucket
resource "aws_s3_object" "init_config" {
  for_each = fileset("./init_config_clamav/", "**")
  bucket   = module.clamav_defs_bucket.s3_bucket_id
  key      = each.value
  source   = "./init_config_clamav/${each.value}"
  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObject*",
      "s3:Get*",
      "s3:ListBucket"
    ]
    resources = [
      module.clamav_defs_bucket.s3_bucket_arn,
      "${module.clamav_defs_bucket.s3_bucket_arn}/*"
    ]
  }
}
