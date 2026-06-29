module "nks" {
  source  = "nirvana-labs/nks/nirvana"
  version = "~> 0.3.0"

  cluster_name       = "labeled-pools-demo"
  kubernetes_version = "v1.34.4"
  project_id         = var.project_id
  region             = "us-sva-2"

  node_pools = {
    # General-purpose pool for most workloads.
    general = {
      node_count    = 1
      instance_type = "n1-highcpu-2"
      labels = {
        workload = "general"
      }
    }
    # Second pool dedicated to premium workloads: labeled so they target it via
    # nodeSelector / nodeAffinity, and tainted so nothing else schedules here.
    # Matching pods need both the nodeSelector and a toleration for the taint.
    # In production this would typically be a memory- or compute-optimized instance type.
    premium = {
      node_count       = 1
      instance_type    = "n1-standard-2"
      boot_volume_size = 80
      labels = {
        workload = "premium"
        tier     = "premium"
      }
      taints = [
        { key = "tier", value = "premium", effect = "NoSchedule" },
      ]
    }
  }

  # Firewall rules default to 0.0.0.0/0 for both the K8s API and ingress VIPs.
  # Scope management_cidrs to your trusted networks before using this cluster for anything non-trivial.
  # management_cidrs = ["10.0.0.0/8"]   # e.g. VPN / bastion egress
  # ingress_cidrs    = ["0.0.0.0/0"]    # public ingress (default)
}
