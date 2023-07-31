output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "List of public subnets created within the Virtual Private Cloud (VPC). These subnets have access to the internet and are suitable for resources that require public accessibility."
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "List of private subnets created within the Virtual Private Cloud (VPC). These subnets are isolated from the internet and are suitable for backend resources that should not be publicly accessible."
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The unique identifier (ID) of the Virtual Private Cloud (VPC) that was created. The VPC is a logically isolated section of the cloud where resources can be launched in a virtual network."
}

output "s3_enpoint_id" {
  description = "The ID of the S3 VPC Endpoint."
  value       = aws_vpc_endpoint.s3.id
}
