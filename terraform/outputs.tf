output "namespace_name" {
  description = "Managed Kubernetes namespace name."
  value       = kubernetes_namespace_v1.music_platform.metadata[0].name
}

output "namespace_labels" {
  description = "Effective labels applied to the managed namespace."
  value       = kubernetes_namespace_v1.music_platform.metadata[0].labels
}
