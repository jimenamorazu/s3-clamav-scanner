locals {
  bucket_names = [for name in ["logging", "definitions", "file-upload"] : "${var.name}-${name}-${var.region}-${var.environment}"]
  lambda_env_variables = {
    DEFS_URL                     = "https://${data.aws_s3_bucket.definitions_bucket.bucket_regional_domain_name}"
    EFS_DEF_PATH                 = "virus_database/"
    EFS_MOUNT_PATH               = local.lambda_mount_path
    POWERTOOLS_METRICS_NAMESPACE = "serverless-clamscan-${var.environment}"
    POWERTOOLS_SERVICE_NAME      = "virus-scan"

  }
  lambda_mount_path   = "/mnt/lambda"
  logging_bucket_name = "${var.name}-${var.region}-logging-bucket"
  bucket_name         = "${var.name}-${var.region}-file-upload"
}