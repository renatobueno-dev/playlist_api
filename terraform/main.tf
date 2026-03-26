provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}

locals {
  required_namespace_labels = {
    "istio-injection"                            = "enabled"
    "pod-security.kubernetes.io/enforce"         = var.pod_security_level
    "pod-security.kubernetes.io/warn"            = var.pod_security_level
    "pod-security.kubernetes.io/audit"           = var.pod_security_level
    "pod-security.kubernetes.io/enforce-version" = var.pod_security_version
    "pod-security.kubernetes.io/warn-version"    = var.pod_security_version
    "pod-security.kubernetes.io/audit-version"   = var.pod_security_version
  }

  effective_namespace_labels = merge(
    var.namespace_labels,
    local.required_namespace_labels,
  )
}

resource "kubernetes_namespace_v1" "music_platform" {
  metadata {
    name        = var.namespace_name
    labels      = local.effective_namespace_labels
    annotations = var.namespace_annotations
  }
}
