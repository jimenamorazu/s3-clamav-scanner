environment           = "dev"
name                  = "s3-scan"
timeout               = 900
lambda_memory         = 3008
vpc_id                = "vpc-0c56494f1525c7841"
s3_vpc_endpoint       = "vpce-0fb2d4b9238165c86"
region                = "us-west-1"
ecr_repo_name         = "lambda/s3-antivirus-scanner"
definitions_bucket_id = "clamav-definitions-manager-us-west-1-definitions"

