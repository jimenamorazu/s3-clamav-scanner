locals {
  lambda_env_variables = {
    DEFS_BUCKET             = module.clamav_defs_bucket.s3_bucket_id
    POWERTOOLS_SERVICE_NAME = "freshclam-update"
  }
  bucket_name = "${var.name}-${var.region}-definitions"
}