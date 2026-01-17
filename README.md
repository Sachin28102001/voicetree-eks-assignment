# EKS Cluster with Karpenter Autoscaling

Production-ready Amazon EKS infrastructure with Karpenter for intelligent node autoscaling, fully automated through Terraform.

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/eks/)
[![Karpenter](https://img.shields.io/badge/Karpenter-v0.32-326CE5)](https://karpenter.sh/)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Deployment Guide](#deployment-guide)
- [Testing Autoscaling](#testing-autoscaling)
- [Multi-Environment Support](#multi-environment-support)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Design Decisions](#design-decisions)

---

## 🚀 Quick Start

### Clone the Repository
\`\`\`bash
git clone https://github.com/Sachin28102001/voicetree-eks-assignment.git
cd voicetree-eks-assignment
\`\`\`

Now proceed with the [Prerequisites](#prerequisites) section below.


## 🎯 Overview

This project implements a production-grade EKS cluster with Karpenter for dynamic node scaling. Everything is managed as Infrastructure as Code using Terraform - no manual kubectl or YAML file applications needed.

### What Makes This Implementation Unique

✅ **Fully Automated** - Karpenter CRDs managed by Terraform  
✅ **Zero Manual Steps** - aws-auth ConfigMap auto-configured  
✅ **Tag-Based Discovery** - VPC/subnets found dynamically via data sources  
✅ **Multi-Environment Ready** - Dev, Pre-Prod, Prod with directory-based separation  

---

## 🏗️ Architecture
```
┌────────────────────────────────────────────────────────────┐
│                      AWS Region                             │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              VPC (CIDR Block)                        │  │
│  │          Tagged for Discovery                        │  │
│  │                                                      │  │
│  │  ┌─────────────┐        ┌─────────────┐            │  │
│  │  │   Public    │        │   Public    │            │  │
│  │  │   Subnet    │        │   Subnet    │            │  │
│  │  │    AZ-1     │        │    AZ-2     │            │  │
│  │  │             │        │             │            │  │
│  │  │ NAT Gateway ├────────┤  Internet   │            │  │
│  │  │             │        │  Gateway    │            │  │
│  │  └──────┬──────┘        └─────────────┘            │  │
│  │         │                                           │  │
│  │  ┌──────▼──────┐        ┌─────────────┐            │  │
│  │  │   Private   │        │   Private   │            │  │
│  │  │   Subnet    │        │   Subnet    │            │  │
│  │  │    AZ-1     │        │    AZ-2     │            │  │
│  │  │             │        │             │            │  │
│  │  │ EKS Nodes   │        │ Karpenter   │            │  │
│  │  │ (Managed)   │        │ Auto-Nodes  │            │  │
│  │  └─────────────┘        └─────────────┘            │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────┐    │  │
│  │  │   EKS Control Plane (Managed by AWS)       │    │  │
│  │  │   - Karpenter Controller                   │    │  │
│  │  │   - aws-auth (Terraform-managed)           │    │  │
│  │  └────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘

Data Flow:
1. VPC created once (vpc-infrastructure/)
2. EKS uses data sources to find VPC via tags
3. Karpenter monitors pending pods
4. Auto-provisions nodes in private subnets
5. Nodes auto-register via aws-auth ConfigMap
```

---

## ✨ Key Features

### Infrastructure
- **EKS 1.29** with managed control plane
- **Karpenter v0.32** for intelligent autoscaling
- **Private subnet deployment** - All nodes in private subnets
- **Multi-AZ setup** - High availability across availability zones

### Automation
- **Zero manual kubectl** - Everything via Terraform
- **Karpenter as Code** - NodePool & EC2NodeClass in Terraform
- **Auto aws-auth** - Karpenter nodes join automatically
- **Data source discovery** - No hardcoded VPC IDs

### Security
- **IRSA** - IAM Roles for Service Accounts (no static credentials)
- **OfficeIPs SG** - Security group attached to worker nodes
- **SSH key support** - For emergency node access
- **Private-only nodes** - No public IPs on worker nodes

---

## 📦 Prerequisites

### Required Tools
```bash
# Terraform >= 1.0
terraform version

# AWS CLI >= 2.0
aws --version

# kubectl >= 1.28
kubectl version --client
```

### AWS Account Setup

1. **Configure AWS CLI**
```bash
aws configure
# Enter: Access Key, Secret Key, Region
```

2. **Create SSH Key Pair**

**Option A: AWS Console (Recommended)**
```
EC2 → Key Pairs → Create Key Pair
Name: <your-key-name>
Type: RSA
Format: .pem
```

**Option B: AWS CLI**
```bash
aws ec2 create-key-pair --key-name <your-key-name> \
  --query 'KeyMaterial' --output text > <your-key-name>.pem
chmod 400 <your-key-name>.pem
```

---

## 📂 Project Structure
```
voicetree-eks-assignment/
│
├── vpc-infrastructure/          # One-time VPC setup
│   ├── main.tf                  # VPC, Subnets, NAT, OfficeIPs SG
│   ├── variables.tf
│   └── outputs.tf
│
├── environments/                # Environment-specific deployments
│   ├── dev/
│   │   ├── data.tf              # 🔍 VPC lookup via tags
│   │   ├── main.tf              # EKS + Karpenter deployment
│   │   ├── variables.tf         # Dev-specific variables
│   │   └── outputs.tf
│   ├── pre-prod/
│   │   └── ...                  # Same structure, different VPC tag
│   └── prod/
│       └── ...                  # Same structure, different VPC tag
│
├── modules/                     # Reusable Terraform modules
│   ├── eks/                     # EKS cluster module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── karpenter/               # Karpenter installation module
│       ├── main.tf              # Helm release, IAM roles
│       ├── variables.tf
│       └── outputs.tf
│
├── screenshots/                 # Proof of deployment
│   ├── aws-console/
│   │   ├── vpc-created.png
│   │   ├── eks-cluster.png
│   │   ├── nodes-list.png
│   │   └── karpenter-scaling.png
│   └── terminal/
│       ├── terraform-apply.png
│       ├── kubectl-nodes.png
│       └── scaling-test.png
│
├── test_scaling.yaml            # 🧪 Test workload for autoscaling
├── backend.tf.example           # S3 backend template (optional)
├── .gitignore
└── README.md
```

### Design Pattern

**Separation of Concerns:**
- `vpc-infrastructure/` → Long-lived infrastructure (create once)
- `environments/*/data.tf` → Dynamic VPC discovery (finds existing VPC)
- `environments/*/main.tf` → Application infrastructure (EKS + Karpenter)

---

## 🚀 Deployment Guide

### Phase 1: VPC Infrastructure (One-Time Setup)

#### Step 1: Deploy VPC
```bash
cd vpc-infrastructure
terraform init
terraform apply -auto-approve
```

**Duration:** ~3-5 minutes

**What gets created:**
- VPC with defined CIDR block
- 2 Public Subnets + 2 Private Subnets
- Internet Gateway + NAT Gateway
- Route Tables
- OfficeIPs Security Group

**Verify VPC tagging:**
```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=<your-vpc-tag>"
```

---

### Phase 2: EKS Cluster Deployment

#### Step 2: Deploy EKS
```bash
cd ../environments/dev
terraform init
terraform apply
```

**Duration:** ~15-20 minutes

**What gets created:**
- EKS Cluster (v1.29)
- Managed Node Group (initial nodes)
- Karpenter Controller (Helm)
- Karpenter IAM Roles (IRSA)
- aws-auth ConfigMap (auto-configured)
- Karpenter NodePool (CRD via Terraform)
- Karpenter EC2NodeClass (CRD via Terraform)

**Progress stages:**
```
[1/5] Creating EKS cluster control plane... (10 min)
[2/5] Launching managed node group... (3 min)
[3/5] Installing Karpenter via Helm... (2 min)
[4/5] Applying Karpenter CRDs... (1 min)
[5/5] Configuring aws-auth... (30 sec)
```

---

### Phase 3: Verification

#### Step 3: Configure kubectl
```bash
aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
kubectl cluster-info
```

#### Step 4: Verify Cluster
```bash
# Check nodes
kubectl get nodes

# Expected output:
# NAME                                        STATUS   ROLES    AGE
# ip-xxx-xxx-xxx-xxx.compute.internal         Ready    <none>   5m
```

#### Step 5: Verify Karpenter
```bash
# Check Karpenter pod
kubectl get pods -n karpenter

# Check Karpenter CRDs
kubectl get nodepool
kubectl get ec2nodeclass

# Expected:
# NAME      READY
# default   True
```

#### Step 6: Verify aws-auth ConfigMap
```bash
kubectl get configmap aws-auth -n kube-system -o yaml
```

**Should contain TWO roles:**
```yaml
mapRoles: |
  - rolearn: arn:aws:iam::xxx:role/eks-node-group-xxx  # Managed nodes
    username: system:node:{{EC2PrivateDNSName}}
    groups: [system:bootstrappers, system:nodes]
  
  - rolearn: arn:aws:iam::xxx:role/Karpenter-xxx       # Karpenter nodes
    username: system:node:{{EC2PrivateDNSName}}
    groups: [system:bootstrappers, system:nodes]
```

---

## 🧪 Testing Autoscaling

### Test 1: Scale Up (Trigger Node Provisioning)

#### Deploy Test Workload
```bash
kubectl apply -f test_scaling.yaml

# Initial state
kubectl get pods
```

#### Trigger Scale-Up
```bash
kubectl scale deployment inflate --replicas=10

# Watch pods
kubectl get pods -w
```

**Expected behavior:**
```
NAME                       READY   STATUS
inflate-xxxxx-xxxxx        1/1     Running    # On existing node
inflate-xxxxx-xxxxx        1/1     Running    # On existing node
inflate-xxxxx-xxxxx        0/1     Pending    # Waiting for Karpenter
inflate-xxxxx-xxxxx        0/1     Pending    # Waiting for Karpenter
... (more Pending)
```

#### Watch Karpenter Provision Nodes

**Terminal 1:**
```bash
kubectl get nodes -w
```

**Terminal 2:**
```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f
```

**Karpenter logs:**
```
INFO  controller.provisioner  "found provisionable pod(s)"
INFO  controller.provisioner  "created nodeclaim"
INFO  controller.nodeclaim    "launched instance"
```

**After 1-2 minutes:**
```bash
kubectl get nodes
```

**Expected: Additional nodes provisioned**

✅ **SUCCESS!** Karpenter auto-scaled the cluster!

---

### Test 2: Scale Down (Node Consolidation)

#### Reduce Workload
```bash
kubectl scale deployment inflate --replicas=1

# Watch nodes
kubectl get nodes -w
```

**After 5 minutes:**
Karpenter will:
1. Detect underutilized nodes
2. Drain pods to remaining nodes
3. Terminate empty nodes

**Final state:** Optimized node count

---

## 🌍 Multi-Environment Support

This project uses **directory-based environment separation**.

### Deploying to Pre-Prod

#### Step 1: Create Pre-Prod VPC
```bash
cd vpc-infrastructure

terraform apply \
  -var="vpc_name=<your-preprod-vpc-tag>" \
  -var="cluster_name=<your-preprod-cluster>" \
  -var="environment=pre-prod"
```

#### Step 2: Deploy Pre-Prod EKS
```bash
cd ../environments/pre-prod
terraform init
terraform apply
```

### Deploying to Production

Same process with production-specific variables:
```bash
# VPC
terraform apply \
  -var="vpc_name=<your-prod-vpc-tag>" \
  -var="environment=prod"

# EKS
cd ../environments/prod
terraform init && terraform apply
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Error: VPC Not Found

**Symptom:**
```
Error: no matching VPC found
```

**Cause:** VPC tags don't match data source filter

**Solution:**
```bash
# Check VPC tags
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]'

# Update data.tf with correct tag
cd environments/dev
vim data.tf  # Update values = ["correct-vpc-tag"]
```

---

#### 2. Error: Subnets Not Found

**Symptom:**
```
Error: no matching subnet found
```

**Cause:** Subnet tags missing or incorrect

**Solution:**
```bash
# Check subnet tags
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>" \
  --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0]]'

# Ensure subnets have correct tags
# Tag format: <vpc-name>-private-<az> or <vpc-name>-public-<az>
```

---

#### 3. Karpenter Pods CrashLoopBackOff

**Symptom:**
```bash
kubectl get pods -n karpenter
# NAME                        READY   STATUS             RESTARTS
# karpenter-xxxxxxxxx-xxxxx   0/1     CrashLoopBackOff   5
```

**Cause:** IRSA role misconfigured or missing permissions

**Solution:**
```bash
# Check Karpenter service account annotation
kubectl describe sa karpenter -n karpenter | grep eks.amazonaws.com/role-arn

# Verify IAM role exists
aws iam get-role --role-name <karpenter-role-name>

# Re-apply Terraform to fix
cd environments/dev
terraform apply -target=module.karpenter
```

---

#### 4. Nodes Not Joining Cluster

**Symptom:**
```bash
kubectl get nodes
# No new nodes appear after scaling deployment
```

**Cause:** aws-auth ConfigMap missing Karpenter role

**Solution:**
```bash
# Check aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Verify Karpenter role is present
# If missing, re-apply Terraform
cd environments/dev
terraform apply -target=kubernetes_config_map_v1_data.aws_auth
```

---

#### 5. Error: Security Group Not Found

**Symptom:**
```
Error: no matching security group found
```

**Cause:** OfficeIPs security group not created or wrong tag

**Solution:**
```bash
# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=OfficeIPs"

# Re-deploy VPC infrastructure
cd vpc-infrastructure
terraform apply
```

---

#### 6. Karpenter Not Scaling Nodes

**Symptom:**
```bash
kubectl get pods
# Pods stuck in Pending state for >5 minutes
```

**Diagnosis:**
```bash
# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter --tail=50

# Check NodePool status
kubectl describe nodepool default
```

**Common Causes & Solutions:**

**a) Instance type restrictions:**
```bash
# Check EC2NodeClass
kubectl describe ec2nodeclass default

# Verify instance types are available in your region
aws ec2 describe-instance-type-offerings --location-type availability-zone \
  --filters Name=location,Values=<your-az> --region <your-region>
```

**b) No capacity in AZ:**
```bash
# Karpenter logs will show:
# "Insufficient capacity" or "InsufficientInstanceCapacity"

# Solution: Add more instance types to EC2NodeClass
cd environments/dev
vim main.tf  # Add more instance families to requirements
terraform apply
```

**c) Subnet has no available IPs:**
```bash
# Check subnet IP availability
aws ec2 describe-subnets --subnet-ids <subnet-id> \
  --query 'Subnets[*].AvailableIpAddressCount'

# Solution: Expand VPC CIDR or use larger subnets
```

---

#### 7. Error: kubectl Command Not Found

**Symptom:**
```
bash: kubectl: command not found
```

**Solution:**
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

---

#### 8. Error: terraform init Fails

**Symptom:**
```
Error: Failed to query available provider packages
```

**Cause:** Network issues or provider registry unavailable

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize with verbose logging
TF_LOG=DEBUG terraform init

# If behind proxy, set proxy variables
export HTTP_PROXY=http://your-proxy:port
export HTTPS_PROXY=http://your-proxy:port
terraform init
```

---

#### 9. EKS Cluster Creation Timeout

**Symptom:**
```
Error: timeout while waiting for state to become 'ACTIVE'
```

**Cause:** AWS resource creation taking longer than expected

**Solution:**
```bash
# Check cluster status in AWS Console
# Or via CLI
aws eks describe-cluster --name <cluster-name> --region <region>

# If status is CREATING, wait 5-10 more minutes
# If status is FAILED, check CloudFormation stack errors:
aws cloudformation describe-stack-events --stack-name <eks-stack-name>

# Delete and retry
terraform destroy -target=module.eks
terraform apply
```

---

#### 10. Permission Denied Errors

**Symptom:**
```
Error: UnauthorizedOperation: You are not authorized to perform this operation
```

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM user/role has required permissions:
# - EC2 full access
# - EKS full access
# - IAM role creation
# - VPC management

# If using temporary credentials, ensure they haven't expired
aws configure list
```

---

### Quick Debug Commands

```bash
# Check all AWS resources created
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Environment,Values=dev

# View Terraform state
cd environments/dev
terraform state list
terraform show

# Validate Terraform configuration
terraform validate
terraform fmt -check

# Force unlock Terraform state (if locked)
terraform force-unlock <lock-id>
```

---

## 🗑️ Cleanup

### ⚠️ CRITICAL: Delete in Correct Order!

**Why?** EKS nodes run in VPC subnets. Deleting VPC first causes dependency errors.

### Step 1: Delete Test Deployment
```bash
kubectl delete deployment inflate
kubectl get nodes -w  # Wait for Karpenter to scale down
```

### Step 2: Destroy EKS Cluster
```bash
cd environments/dev
terraform destroy -auto-approve
```

**Duration:** ~10-15 minutes

**Verify deletion:**
```bash
aws eks list-clusters --region <your-region>
# Should NOT show your cluster
```

### Step 3: Destroy VPC Infrastructure
```bash
cd ../../vpc-infrastructure
terraform destroy -auto-approve
```

**Duration:** ~3-5 minutes (NAT Gateway takes time)

**Verify complete cleanup:**
```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=<your-vpc-tag>"
# Should return empty
```

---

## 🧠 Design Decisions

### 1. Why Separate VPC Infrastructure?

**Decision:** VPC in separate Terraform project

**Rationale:**
- ✅ Lifecycle mismatch - VPC is long-lived, EKS clusters are ephemeral
- ✅ Blast radius reduction - `terraform destroy` on EKS won't delete VPC
- ✅ Real-world pattern - Mirrors enterprise infrastructure management

---

### 2. Why Manage Karpenter CRDs in Terraform?

**Decision:** Use `kubectl_manifest` for NodePool & EC2NodeClass

**Rationale:**
- ✅ Single source of truth - All infrastructure in Git
- ✅ No manual kubectl apply - Fully automated
- ✅ Drift detection - `terraform plan` shows changes

**Alternative rejected:** Separate YAML files (requires manual steps)

---

### 3. Why Auto-Manage aws-auth ConfigMap?

**Decision:** Use `kubernetes_config_map_v1_data` to inject Karpenter role

**Rationale:**
- ✅ Zero manual intervention - Karpenter nodes join immediately
- ✅ Prevents "Node not registered" error
- ✅ Idempotent - `force = true` ensures consistency

**Manual approach (rejected):**
```bash
kubectl edit configmap aws-auth -n kube-system  # Error-prone, not IaC
```

---

### 4. State Management

**Current:** Local state (assignment-friendly)

**Production:** S3 backend recommended

**How to enable:**
```bash
# 1. Create S3 bucket & DynamoDB table
aws s3 mb s3://<your-state-bucket> --region <your-region>
aws dynamodb create-table --table-name terraform-state-lock ...

# 2. Copy backend config
cp backend.tf.example backend.tf

# 3. Migrate state
terraform init -migrate-state
```

---

## 📝 Assignment Requirements Checklist

### ✅ 1. EKS Cluster Setup
- [x] Provision EKS cluster using Terraform
- [x] Implement Karpenter for dynamic node management
- [x] All infrastructure as IaC (no manual steps)

### ✅ 2. Networking Configuration
- [x] Deploy EKS in existing VPC (via data sources)
- [x] Use private subnets only
- [x] Retrieve VPC/subnet IDs dynamically
- [x] Define data sources in `data.tf`
- [x] Use resource tagging for discovery

### ✅ 3. Security Configuration
- [x] Attach OfficeIPs security group to worker nodes
- [x] Configure SSH key pair for node access

### ✅ 4. Multi-Environment Support
- [x] Support dev, pre-prod, prod environments
- [x] Directory-based separation (best practice)

### ✅ 5. Code Organization
- [x] Modular Terraform design (eks, karpenter modules)
- [x] Follow Terraform best practices
- [x] Comprehensive documentation

---

## 📸 Screenshots and Proof of Deployment

All deployment screenshots are available in the `screenshots/` directory:

### AWS Console Screenshots
- VPC and subnet creation
- EKS cluster dashboard
- EC2 instances (nodes)
- Karpenter scaling in action

### Terminal Outputs
- Terraform apply logs
- kubectl commands
- Scaling test results

---

## 🎓 Additional Resources

**Official Documentation:**
- [Amazon EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Karpenter Documentation](https://karpenter.sh/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

**Learning:**
- [EKS Workshop](https://www.eksworkshop.com/)
- [Karpenter Best Practices](https://karpenter.sh/docs/concepts/)

---

## 👤 Author

**Assignment Submission**  
Position: DevOps Engineer    
Date: January 2026

---

**End of Documentation** 🎯
