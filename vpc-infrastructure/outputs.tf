output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for EKS"
  value       = aws_subnet.private[*].id
}

output "office_security_group_id" {
  description = "OfficeIPs security group ID"
  value       = aws_security_group.office_ips.id
}

output "deployment_summary" {
  description = "VPC deployment summary"
  value = {
    vpc_id          = aws_vpc.main.id
    private_subnets = aws_subnet.private[*].id
    environment     = var.environment
  }
}
