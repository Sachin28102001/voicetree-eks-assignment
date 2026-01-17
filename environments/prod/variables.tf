variable "env_name" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "voicetree-prod-cluster"
}

variable "ssh_key_name" {
  description = "SSH key pair name for EKS nodes"
  type        = string
  default     = "voicetree-eks-key"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Terraform   = "true"
    ManagedBy   = "Terraform"
    Project     = "Voicetree-Assignment"
  }
}
