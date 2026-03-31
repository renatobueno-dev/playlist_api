output "namespace_name" {
  description = "Managed Kubernetes namespace name."
  value       = kubernetes_namespace_v1.music_platform.metadata[0].name
}

output "namespace_labels" {
  description = "Effective labels applied to the managed namespace."
  value       = kubernetes_namespace_v1.music_platform.metadata[0].labels
}

output "platform_guardrails_enabled" {
  description = "Whether baseline namespace guardrails are managed by Terraform."
  value       = var.enable_platform_guardrails
}

output "resource_quota_name" {
  description = "Baseline ResourceQuota name when guardrails are enabled."
  value       = try(kubernetes_resource_quota_v1.baseline[0].metadata[0].name, null)
}

output "limit_range_name" {
  description = "Baseline LimitRange name when guardrails are enabled."
  value       = try(kubernetes_limit_range_v1.baseline[0].metadata[0].name, null)
}
