variable "environment" {
  description = "A string like prod or staging that is added to the lambda name to identify which environment is associated with."
  type        = string
}

variable "region" {
  description = "AWS region where the infrastructure will be deployed."
  type        = string
}

variable "name" {
  description = "The name to be used to identify the resources."
  type        = string
}

variable "lambda_memory" {
  description = "Memory allocation for Lambda Function"
  type        = number
}

variable "lambda_env_variables" {
  description = "A map of the environment variables you want to set in the lambda before each run."
  type        = map(string)
  default     = {}
}

variable "lambda_image_tag" {
  description = "Optional ECR image tag to be used with the provided lambda_image_name. The tag defaults to your chosen env; however, you can use this to override it. Do not provide this if you provide lambda_bucket_name or lambda_source_path."
  type        = string
  default     = null
}

variable "timeout" {
  description = "How many seconds the lambda runs before timeout. Must be between 1 and 900."
  type        = number
  validation {
    condition     = var.timeout > 0 && var.timeout < 901
    error_message = "The timeout value must be between 1 and 900."
  }
}

variable "vpc_id" {
  description = "VPC to link the lambda function to and create a security group in. If this is a Lambda@Edge function, this is not needed."
}

variable "s3_vpc_endpoint" {
  description = "VPC S3 Endpoint to set up bucket permissions."
}

variable "ecr_repo_name" {
  description = "Name of ECR reporitory to create"
  type        = string
}

variable "definitions_bucket_id" {
  description = "ID of S3 bucket that keeps the definitions of clamav."
  type        = string
}