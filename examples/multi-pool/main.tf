module "nks" {
  source  = "nirvana-labs/nks/nirvana"
  version = "~> 0.3.0"

  cluster_name       = "multi-pool-demo"
  kubernetes_version = "v1.34.4"
  project_id         = var.project_id
  region             = "us-sva-2"

  node_pools = {
    general = {
      node_count    = 1
      instance_type = "n1-highcpu-2"
    }
    compute = {
      node_count       = 1
      instance_type    = "n1-standard-2"
      boot_volume_size = 80
    }
  }

  # K8s API is restricted to the 10.0.0.0/8 private range; ingress is public.
  # Defaults are 0.0.0.0/0 for both — always scope management_cidrs for real clusters.
  management_cidrs = ["10.0.0.0/8"]
  ingress_cidrs    = ["0.0.0.0/0"]
}
