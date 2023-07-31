
output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.lambda_function.function_name
}

output "lambda_function_arn" {
  description = "The Amazon Resource Name (ARN) of the Lambda function."
  value       = aws_lambda_function.lambda_function.arn
}

output "lambda_role_name" {
  description = "The name of the IAM role associated with the Lambda function."
  value       = aws_iam_role.lambda_role.name
}

output "lambda_role_arn" {
  description = "The Amazon Resource Name (ARN) of the IAM role associated with the Lambda function."
  value       = aws_iam_role.lambda_role.arn
}

output "security_group_id" {
  description = "The ID of the Security Group associated with the Lambda function."
  value       = var.vpc_id != null ? module.lambda_sg[0].security_group_id : null
}
