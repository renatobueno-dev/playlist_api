variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file used by the Kubernetes provider."
  default     = "~/.kube/config"

  validation {
    condition     = length(trimspace(var.kubeconfig_path)) > 0
    error_message = "kubeconfig_path must be a non-empty path."
  }
}

variable "namespace_name" {
  type        = string
  description = "Namespace managed as Terraform baseline."
  default     = "music-platform"

  validation {
    condition = (
      length(var.namespace_name) <= 63
      && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace_name))
    )
    error_message = "namespace_name must be a valid RFC 1123 DNS label (lowercase alphanumeric or '-', max 63 chars)."
  }
}

variable "namespace_labels" {
  type        = map(string)
  description = "Optional custom labels for the managed namespace."
  default     = {}
}

variable "namespace_annotations" {
  type        = map(string)
  description = "Optional custom annotations for the managed namespace."
  default     = {}
}

variable "pod_security_level" {
  type        = string
  description = "Pod Security Standards level applied to namespace labels."
  default     = "restricted"

  validation {
    condition     = contains(["privileged", "baseline", "restricted"], var.pod_security_level)
    error_message = "pod_security_level must be one of: privileged, baseline, restricted."
  }
}

variable "pod_security_version" {
  type        = string
  description = "Pod Security Standards version for namespace labels."
  default     = "latest"

  validation {
    condition     = length(trimspace(var.pod_security_version)) > 0
    error_message = "pod_security_version must be non-empty (for example: latest or v1.30)."
  }
}

variable "enable_platform_guardrails" {
  type        = bool
  description = "When true, manage baseline namespace guardrails (ResourceQuota and LimitRange)."
  default     = true
}

variable "resource_quota_hard" {
  type        = map(string)
  description = "Hard limits for namespace baseline ResourceQuota."
  default = {
    pods                   = "20"
    services               = "10"
    persistentvolumeclaims = "5"
    "requests.cpu"         = "2"
    "requests.memory"      = "2Gi"
    "limits.cpu"           = "4"
    "limits.memory"        = "4Gi"
  }

  validation {
    condition     = length(var.resource_quota_hard) > 0
    error_message = "resource_quota_hard must define at least one quota key."
  }
}

variable "limit_range_default" {
  type        = map(string)
  description = "Default container limits applied by namespace LimitRange."
  default = {
    cpu    = "500m"
    memory = "512Mi"
  }

  validation {
    condition     = length(var.limit_range_default) > 0
    error_message = "limit_range_default must define at least one limit key."
  }
}

variable "limit_range_default_request" {
  type        = map(string)
  description = "Default container requests applied by namespace LimitRange."
  default = {
    cpu    = "100m"
    memory = "128Mi"
  }

  validation {
    condition     = length(var.limit_range_default_request) > 0
    error_message = "limit_range_default_request must define at least one request key."
  }
}
