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

  platform_guardrail_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "music-platform"
    "platform.music/guardrail"     = "baseline"
  }
}

resource "kubernetes_namespace_v1" "music_platform" {
  metadata {
    name        = var.namespace_name
    labels      = local.effective_namespace_labels
    annotations = var.namespace_annotations
  }
}

resource "kubernetes_resource_quota_v1" "baseline" {
  count = var.enable_platform_guardrails ? 1 : 0

  metadata {
    name      = "${var.namespace_name}-baseline-quota"
    namespace = kubernetes_namespace_v1.music_platform.metadata[0].name
    labels    = local.platform_guardrail_labels
  }

  spec {
    hard = var.resource_quota_hard
  }
}

resource "kubernetes_limit_range_v1" "baseline" {
  count = var.enable_platform_guardrails ? 1 : 0

  metadata {
    name      = "${var.namespace_name}-baseline-limits"
    namespace = kubernetes_namespace_v1.music_platform.metadata[0].name
    labels    = local.platform_guardrail_labels
  }

  spec {
    limit {
      type            = "Container"
      default         = var.limit_range_default
      default_request = var.limit_range_default_request
    }
  }
}
