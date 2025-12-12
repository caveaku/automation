variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
  default     = "dev-your-unique-suffix" # e.g., dev-<yourname>-1234
}

variable "allowed_cidr" {
  description = "CIDR allowed to access RDS (e.g., your office IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "masteruser"
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}
