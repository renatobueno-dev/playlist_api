provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}

locals {
  required_namespace_labels = {
    "istio-injection" = "enabled"
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
