module "nks" {
  source  = "nirvana-labs/nks/nirvana"
  version = "~> 0.3.0"

  cluster_name       = "scale-to-zero-demo"
  kubernetes_version = var.kubernetes_version
  project_id         = var.project_id
  region             = "us-sva-2"

  node_pools = {
    # Baseline pool. The cluster needs at least one worker to provision and to
    # host CoreDNS, so keep one pool at node_count >= 1 — don't set every pool to 0.
    base = {
      node_count    = 1
      instance_type = "n1-highcpu-2"
    }

    # Scale-from-zero pool: starts empty and is grown by the autoscaler when a
    # pod that tolerates the taint is pending. Tainted so only those workloads
    # land here (e.g. burst or GPU jobs). Taints are immutable after creation.
    burst = {
      node_count    = 0
      instance_type = "n1-standard-2"
      taints = [
        { key = "dedicated", value = "burst", effect = "NoSchedule" },
      ]
    }
  }

  fetch_kubeconfig = var.fetch_kubeconfig
}
