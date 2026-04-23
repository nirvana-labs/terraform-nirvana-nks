variable "cluster_id" {
  description = "ID of the NKS cluster to add the node pool to."
  type        = string
}

variable "name" {
  description = "Name of the node pool."
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the pool (1-100)."
  type        = number

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "node_count must be between 1 and 100."
  }
}

variable "instance_type" {
  description = "Instance type for the nodes (e.g. n1-standard-8)."
  type        = string
}

variable "boot_volume_size" {
  description = "Boot volume size in GB (64-512)."
  type        = number
  default     = 100

  validation {
    condition     = var.boot_volume_size >= 64 && var.boot_volume_size <= 512
    error_message = "boot_volume_size must be between 64 and 512 GB."
  }
}

variable "boot_volume_type" {
  description = "Boot volume type: nvme or abs."
  type        = string
  default     = "abs"

  validation {
    condition     = contains(["nvme", "abs"], var.boot_volume_type)
    error_message = "boot_volume_type must be \"nvme\" or \"abs\"."
  }
}

variable "labels" {
  description = "Kubernetes labels to apply to each node in the pool. Keys under the kubernetes.io, k8s.io, and nirvanalabs.io prefixes are reserved by the platform."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to attach to the node pool."
  type        = list(string)
  default     = []
}
