provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
      Terraform   = "True"
      Path        = lower(split("s3-clamav-scanner", abspath(path.root))[1])
    }
  }
}