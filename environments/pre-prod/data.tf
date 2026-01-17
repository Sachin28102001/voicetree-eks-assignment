data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["voicetree-pre-prod-vpc"]
  }
}

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
