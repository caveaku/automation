output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
}

output "s3_bucket_name" {
  value = aws_s3_bucket.dev.bucket
}

output "rds_endpoint" {
  value       = aws_db_instance.postgres.address
  description = "RDS PostgreSQL endpoint"
}

output "rds_port" {
  value = aws_db_instance.postgres.port
}
