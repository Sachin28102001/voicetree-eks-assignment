module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id   
  subnet_ids = var.subnet_ids
  enable_irsa = true

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]
      min_size     = 1
      max_size     = 2
      desired_size = 1
      
      # Attach OfficeIPs security group
      vpc_security_group_ids = [var.office_sg_id]
      
      # SSH key configuration
      key_name = var.ssh_key_name
    }
  }
}
