output "cluster_id" {
  value = module.nks.cluster_id
}

output "node_pool_ids" {
  value = module.nks.node_pool_ids
}

output "kubeconfig_path" {
  value = module.nks.kubeconfig_path
}
