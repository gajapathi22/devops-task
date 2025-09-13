terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" { 
  default = "ap-south-1" 
}

variable "cluster_name" { 
  default = "devops-task-eks" 
}

variable "app_name" { 
  default = "devops-task" 
}

# ECR repository
resource "aws_ecr_repository" "app" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.app_name
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get public subnets only from default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# EKS cluster with managed node group
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  # Cluster access configuration
  cluster_endpoint_public_access = true

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    default = {
      name = "default-node-group"

      instance_types = ["t2.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Node group configuration
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"
      disk_size      = 20

      # Remote access (optional)
      # remote_access = {
      #   ec2_ssh_key = "your-key-pair-name"
      # }

      tags = {
        Environment = "dev"
        Terraform   = "true"
      }
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Outputs
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "ecr_repo_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}