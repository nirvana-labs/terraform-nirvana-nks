module "nks" {
  source = "../../"

  cluster_name = "multi-pool-demo"
  project_id   = var.project_id
  region       = "us-sva-2"

  node_pools = {
    general = {
      node_count    = 3
      instance_type = "n1-standard-8"
    }
    compute = {
      node_count       = 2
      instance_type    = "n1-standard-16"
      boot_volume_size = 200
    }
  }

  # K8s API is restricted to the 10.0.0.0/8 private range; ingress is public.
  # Defaults are 0.0.0.0/0 for both — always scope management_cidrs for real clusters.
  management_cidrs = ["10.0.0.0/8"]
  ingress_cidrs    = ["0.0.0.0/0"]
}
