variable "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks for private subnets in the VPC."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.private_subnets_cidr_blocks : can(regex("^((?:[0-9]{1,3}\\.){3}[0-9]{1,3})\\/([0-9]|[1-2][0-9]|3[0-2])$", cidr))])
    error_message = "Invalid CIDR block format for private subnets. Each CIDR block should be in the form 'x.x.x.x/xx', where x is an IPv4 address and xx is a number between 0 and 32 representing the prefix length."
  }
}

variable "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks for public subnets in the VPC."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.public_subnets_cidr_blocks : can(regex("^((?:[0-9]{1,3}\\.){3}[0-9]{1,3})\\/([0-9]|[1-2][0-9]|3[0-2])$", cidr))])
    error_message = "Invalid CIDR block format for public subnets. Each CIDR block should be in the form 'x.x.x.x/xx', where x is an IPv4 address and xx is a number between 0 and 32 representing the prefix length."
  }
}

variable "environment" {
  description = "Environment name for the infrastructure, e.g., 'dev', 'prod', etc."
  type        = string
}

variable "region" {
  description = "AWS region where the infrastructure will be deployed."
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  validation {
    condition     = can(regex("^((?:[0-9]{1,3}\\.){3}[0-9]{1,3})\\/([0-9]|[1-2][0-9]|3[0-2])$", var.cidr_block))
    error_message = "Invalid CIDR block format. It should be in the form 'x.x.x.x/xx', where x is an IPv4 address and xx is a number between 0 and 32 representing the prefix length."
  }
}

variable "availability_zones" {
  description = "List of availability zones where subnets will be created."
  type        = list(string)
}

