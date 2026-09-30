variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "ecr_repository_name" {
  description = "Private ECR repository for Helm charts"
  type        = string
  default     = "ml-api-helm"
}

variable "helm_release_name" {
  description = "Helm release name"
  type        = string
  default     = "ml-api"
}

variable "helm_chart_version" {
  description = "Version of the Helm chart"
  type        = string
  default     = "0.1.0"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}