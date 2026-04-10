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

  management_cidrs = ["10.0.0.0/8"]
  ingress_cidrs    = ["0.0.0.0/0"]
}
