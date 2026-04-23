module "nks" {
  source = "../../"

  cluster_name = "basic-demo"
  project_id   = var.project_id
  region       = "us-sva-2"

  node_pools = {
    default = {
      node_count    = 2
      instance_type = "n1-standard-8"
    }
  }

  # Firewall rules default to 0.0.0.0/0 for both the K8s API and ingress VIPs.
  # Scope management_cidrs to your trusted networks before using this cluster for anything non-trivial.
  # management_cidrs = ["10.0.0.0/8"]   # e.g. VPN / bastion egress
  # ingress_cidrs    = ["0.0.0.0/0"]    # public ingress (default)

  # fetch_kubeconfig = true   # uncomment after the first apply (~10 min wait)
}
