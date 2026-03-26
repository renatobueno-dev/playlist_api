variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file used by the Kubernetes provider."
  default     = "~/.kube/config"
}

variable "namespace_name" {
  type        = string
  description = "Namespace managed as Terraform baseline."
  default     = "music-platform"
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
  default     = "baseline"
}

variable "pod_security_version" {
  type        = string
  description = "Pod Security Standards version for namespace labels."
  default     = "latest"
}
