terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get AZs for subnets
data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tf-main-vpc"
  }
}

# Subnet 1
resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-subnet-1"
  }
}

# Subnet 2
resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-subnet-2"
  }
}

# Route table 1 (for subnet_1)
resource "aws_route_table" "rtb_1" {
  vpc_id = aws_vpc.main.id

  # Implicit local route always exists; add more routes if needed.

  tags = {
    Name = "tf-rtb-1"
  }
}

resource "aws_route_table_association" "rtb_assoc_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rtb_1.id
}

# Route table 2 (for subnet_2)
resource "aws_route_table" "rtb_2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-rtb-2"
  }
}

resource "aws_route_table_association" "rtb_assoc_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.rtb_2.id
}

# S3 bucket (update to a globally-unique name before apply!)
resource "aws_s3_bucket" "dev" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "dev-bucket"
  }
}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "tf-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from allowed CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr] # tighten this in real setups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-rds-sg"
  }
}

# DB subnet group for RDS
resource "aws_db_subnet_group" "rds_subnets1" {
  name       = "tf-rds-subnet-group"
  subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  tags = {
    Name = "tf-rds-subnet-group"
  }
}

# RDS PostgreSQL 15 instance
resource "aws_db_instance" "postgres" {
  identifier        = "tf-postgres15-db"
  allocated_storage = 20

  engine         = "postgres"
  engine_version = "17.7" # adjust if AWS supports a newer minor
  instance_class = "db.t3.micro"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds_subnets1.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true

  backup_retention_period = 1

  tags = {
    Name = "tf-postgres15"
  }
}
