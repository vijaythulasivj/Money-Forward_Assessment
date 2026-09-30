output "ecr_repository_url" {
  description = "Private ECR repository URL for Helm charts"
  value       = aws_ecr_repository.helm_charts.repository_url
}

output "helm_release_name" {
  description = "Helm release name"
  value       = helm_release.ml_api.name
}

output "helm_release_namespace" {
  description = "Kubernetes namespace used by the Helm release"
  value       = helm_release.ml_api.namespace
}