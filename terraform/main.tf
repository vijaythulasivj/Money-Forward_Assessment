# Illustrative IaC configuration for the MLOps assignment.
#
# This configuration demonstrates how the private ECR OCI Helm
# repository and Helm deployment could be managed using Terraform.
#
# The configuration is not executed in this assignment because
# no AWS account is available in the assessment environment.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "helm_charts" {
  name = var.ecr_repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Helm OCI Repository"
  }
}

# Illustrative example.
# In a real environment, the Helm provider would be configured
# with the target Kubernetes cluster credentials.

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "ml_api" {
  name      = var.helm_release_name
  namespace = var.environment

  repository = "oci://REPLACE_WITH_ECR_REGISTRY/${var.ecr_repository_name}"
  chart      = "ml-api"
  version    = var.helm_chart_version

  create_namespace = true

  values = [
    file("${path.module}/../helm/ml-api/values-${var.environment}.yaml")
  ]
}