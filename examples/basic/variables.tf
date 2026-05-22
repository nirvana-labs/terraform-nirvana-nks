variable "project_id" {
  description = "Nirvana Labs project ID."
  type        = string
}

variable "fetch_kubeconfig" {
  description = "Whether to fetch the cluster kubeconfig. Flip to true on a second apply once the control plane is reachable (~10 min after the first apply)."
  type        = bool
  default     = false
}
