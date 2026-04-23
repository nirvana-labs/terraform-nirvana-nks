module "nks" {
  source = "../../"

  cluster_name = "labeled-pools-demo"
  project_id   = var.project_id
  region       = "us-sva-2"

  node_pools = {
    # General-purpose pool for most workloads.
    general = {
      node_count    = 2
      instance_type = "n1-standard-8"
      labels = {
        workload = "general"
      }
    }
    # Memory-optimized pool targeted by nodeSelector / nodeAffinity on memory-hungry Pods.
    memory = {
      node_count       = 2
      instance_type    = "n1-standard-16"
      boot_volume_size = 200
      labels = {
        workload = "memory"
        tier     = "premium"
      }
    }
  }

  # Firewall rules default to 0.0.0.0/0 for both the K8s API and ingress VIPs.
  # Scope management_cidrs to your trusted networks before using this cluster for anything non-trivial.
  # management_cidrs = ["10.0.0.0/8"]   # e.g. VPN / bastion egress
  # ingress_cidrs    = ["0.0.0.0/0"]    # public ingress (default)
}
