module "nks" {
  source = "../../../"

  cluster_name       = "terratest-basic"
  kubernetes_version = var.kubernetes_version
  project_id         = var.project_id
  region             = "us-sva-2"

  node_pools = {
    default = {
      node_count    = 1
      instance_type = "n1-highcpu-2"
    }
  }

  fetch_kubeconfig = var.fetch_kubeconfig
}
