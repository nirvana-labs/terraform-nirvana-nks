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

  fetch_kubeconfig = true
}
