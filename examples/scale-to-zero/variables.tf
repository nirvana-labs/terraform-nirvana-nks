variable "project_id" {
  description = "Nirvana Labs project ID."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster."
  type        = string
  default     = "v1.34.4"
}

variable "fetch_kubeconfig" {
  description = "Whether to fetch the cluster kubeconfig. Flip to true on a second apply once the control plane is reachable (~10 min after initial apply)."
  type        = bool
  default     = false
}
