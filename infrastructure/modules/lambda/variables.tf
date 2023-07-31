variable "environment" {
  description = "A string like prod or staging that is added to the lambda name to identify which environment is associated with."
  type        = string
  default     = ""
}

variable "lambda_name" {
  description = "The name of the lambda."
  type        = string
  default     = ""
}

variable "lambda_env_variables" {
  description = "A map of the environment variables you want to set in the lambda before each run."
  type        = map(string)
  default     = null
}

variable "lambda_tags" {
  description = "A map tags to add to the lambda function."
  type        = map(string)
  default     = {}
}

variable "lambda_handler" {
  description = "The function to call when the lambda executes. Set to null for lambdas with image source."
  type        = string
  default     = null
}

variable "lambda_memory" {
  description = "Memory allocation for Lambda Function"
  type        = number
  default     = 128
}

variable "lambda_runtime" {
  description = "Runtime for lambda function."
  type        = string
  default     = null
}

variable "lambda_at_edge" {
  description = "Set this to true if using Lambda@Edge, to enable publishing, limit the timeout, and allow edgelambda.amazonaws.com to invoke the function."
  type        = bool
  default     = false
}

variable "publish" {
  description = "Enables version publishing."
  type        = bool
  default     = false
}

variable "timeout" {
  description = "How many seconds the lambda runs before timeout. Must be between 1 and 900."
  type        = number
  default     = 3
  validation {
    condition     = var.timeout > 0 && var.timeout < 901
    error_message = "The timeout value must be between 1 and 900."
  }
}

variable "lambda_layers" {
  description = "A list of strings representing the lambda layers to include with this lambda."
  type        = list(string)
  default     = []
}

variable "reserved_concurrent_executions" {
  description = "Number of reserved executions for the lambda function."
  type        = number
  default     = null
}

# IAM policy data source to be injected
variable "lambda_policy_json" {
  description = "Policy documents in JSON format to attach to the lambda function."
  default     = null
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC to link the lambda function to and create a security group in. If this is a Lambda@Edge function, this is not needed."
  default     = null
}

# Source of lambda function
# S3
variable "lambda_bucket_name" {
  description = "Bucket name where function source code is located. Do not provide this if you provide lambda_source_path or lambda_image_uri."
  default     = null
}

variable "code_key" {
  description = "A string name of the S3 key the lambda code is stored in."
  type        = string
  default     = null
}

# Filename
variable "lambda_source_path" {
  description = "The absolute path to a local file or directory containing the Lambda source code. Do not provide this if you provide lambda_bucket_name or lambda_image_uri."
  type        = string
  default     = null
}

# ECR Image
variable "ecr_repo_arn" {
  description = "ECR repository arn to be used as the lambda source. Do not provide this if you provide lambda_bucket_name or lambda_source_path."
  type        = string
  default     = null
}

variable "ecr_repo_url" {
  description = "ECR repository URL to be used as the lambda source. Do not provide this if you provide lambda_bucket_name or lambda_source_path."
  type        = string
  default     = null
}

variable "image_tag" {
  description = "Optional ECR image tag to be used with the provided lambda_image_name. The tag defaults to your chosen env; however, you can use this to override it. Do not provide this if you provide lambda_bucket_name or lambda_source_path."
  type        = string
  default     = null
}

# NFS 

variable "file_system_config" {
  description = "A map of file system configuration for the Lambda function."
  type        = list(map(any))
  default     = null
}

variable "efs_security_group_id" {
  description = "The ID of the Security Group that allows EFS access to the Lambda function."
  type        = string
  default     = null
}