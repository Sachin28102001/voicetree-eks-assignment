output "karpenter_arn" {
  value = module.karpenter.irsa_arn
}

output "role_arn" {
  description = "IAM Role ARN of the Karpenter Node Group"
  value       = module.karpenter.role_arn
}

output "role_name" {
  description = "The name of the IAM role created for Karpenter nodes"
  value       = module.karpenter.role_name
}
