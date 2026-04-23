variable "cluster_name" {
  description = "Name of the NKS cluster."
  type        = string
  default     = "my-cluster"
}

variable "project_id" {
  description = "Nirvana Labs project ID."
  type        = string
}

# NKS is currently available in us-sva-2 only.
variable "region" {
  description = "Nirvana Labs region to deploy in."
  type        = string
  default     = "us-sva-2"
}

variable "create_vpc" {
  description = "Whether to create a new VPC. Set to false and provide vpc_id to use an existing VPC."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of an existing VPC. Required when create_vpc is false. Only one NKS cluster per VPC is supported."
  type        = string
  default     = null
}

variable "vpc_name" {
  description = "Name for the created VPC and subnet. Defaults to cluster_name. Ignored when vpc_id is set."
  type        = string
  default     = null
}

variable "node_pools" {
  description = "Map of worker node pool definitions. Keys are pool names."
  type = map(object({
    node_count       = number
    instance_type    = string
    boot_volume_size = optional(number, 100)
    boot_volume_type = optional(string, "abs")
    labels           = optional(map(string), {})
    tags             = optional(list(string), [])
  }))

  validation {
    condition     = length(var.node_pools) >= 1
    error_message = "At least one node pool must be defined."
  }

  validation {
    condition     = alltrue([for k, v in var.node_pools : v.boot_volume_size >= 64 && v.boot_volume_size <= 512])
    error_message = "boot_volume_size must be between 64 and 512 GB."
  }

  validation {
    condition     = alltrue([for k, v in var.node_pools : contains(["nvme", "abs"], v.boot_volume_type)])
    error_message = "boot_volume_type must be \"nvme\" or \"abs\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_pools : alltrue([for lk in keys(v.labels) : !can(regex("^(kubernetes\\.io|k8s\\.io|nirvanalabs\\.io)(/|$)", lk))])])
    error_message = "Label keys under the kubernetes.io, k8s.io, and nirvanalabs.io prefixes are reserved by the platform."
  }
}

variable "management_cidrs" {
  description = "CIDRs allowed to access the Kubernetes API (443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_cidrs" {
  description = "CIDRs allowed to access the shared ingress (HTTP 80, HTTPS 443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_firewall_rules" {
  description = "Whether to create the default access firewall rules."
  type        = bool
  default     = true
}

variable "fetch_kubeconfig" {
  description = "Whether to fetch the cluster kubeconfig and write it to kubeconfig_path. Set to true only after the cluster is ready (~10 minutes after initial apply); fetching before the control plane is reachable will fail."
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Path to write the kubeconfig file when fetch_kubeconfig is true. Defaults to .secrets/kubeconfig-<cluster_name> relative to the root module."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to attach to all resources."
  type        = list(string)
  default     = []
}
