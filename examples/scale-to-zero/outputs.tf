output "cluster_id" {
  value = module.nks.cluster_id
}

output "cluster_public_ip" {
  value = module.nks.cluster_public_ip
}

output "kubeconfig_path" {
  value = module.nks.kubeconfig_path
}

output "node_pool_ids" {
  value = module.nks.node_pool_ids
}
