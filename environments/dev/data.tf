# 1. Search for Existing VPC
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["voicetree-dev-vpc"] 
  }
}

# 2. Search for Private Subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

# 3. Search for Security Group
data "aws_security_group" "office" {
  filter {
    name   = "group-name"
    values = ["OfficeIPs"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}
